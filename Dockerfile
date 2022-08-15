FROM centos:8

ENV _CONTAINERS_USERNS_CONFIGURED="" \
    KUBECTL="https://dl.k8s.io/release/v1.21.0/bin/linux/amd64/kubectl" \
    HELM_BINARY="https://get.helm.sh/helm-v3.8.1-linux-amd64.tar.gz" \
    CONTAINER_CONF="https://raw.githubusercontent.com/containers/libpod/master/contrib/podmanimage/stable/containers.conf" \
    PODMAN_CONTAINER_CONF="https://raw.githubusercontent.com/containers/libpod/master/contrib/podmanimage/stable/podman-containers.conf"


RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* \
 && sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* \
 && yum update -y \
 && yum install -y podman jq gettext crun shadow-utils fuse-overlayfs --exclude container-selinux \
 && rm -rf /var/cache /var/log/dnf* /var/log/yum.*


RUN useradd podman \
 && echo podman:10000:5000 > /etc/subuid \
 && echo podman:10000:5000 > /etc/subgid \
 && chown podman:podman -R /home/podman


VOLUME /var/lib/containers
VOLUME /home/podman/.local/share/containers


ADD ${CONTAINER_CONF} /etc/containers/containers.conf
ADD ${PODMAN_CONTAINER_CONF} /home/podman/.config/containers/containers.conf


RUN chmod 644 /etc/containers/containers.conf \
 && sed -i -e 's|^#mount_program|mount_program|g' \
           -e '/additionalimage.*/a "/var/lib/shared",' \
           -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' /etc/containers/storage.conf


RUN mkdir -p /var/lib/shared/{overlay-images,overlay-layers,vfs-images,vfs-layers} \
 && touch /var/lib/shared/overlay-images/images.lock \
 && touch /var/lib/shared/overlay-layers/layers.lock \
 && touch /var/lib/shared/vfs-images/images.lock \
 && touch /var/lib/shared/vfs-layers/layers.lock


WORKDIR /usr/local/bin/

RUN curl -LOs ${KUBECTL} \
 && chmod +x kubectl \
 && curl -LOs ${HELM_BINARY} \
 && tar -zxf ${HELM_BINARY##*/} \
 && mv linux-amd64/helm /usr/local/bin/helm