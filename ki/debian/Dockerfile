FROM debian:9.3

ENV container docker

ENV DEBIAN_FRONTEND noninteractive
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

RUN apt-get update && apt-get upgrade -y && apt-get install -y openssh-server curl lsb-release sudo make locales python build-essential aptitude git rsync jq netcat
RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure --frontend=noninteractive locales

RUN groupadd -g 497 docker
RUN groupadd -g 1000 ubuntu
RUN useradd -u 1000 -g ubuntu -d /home/ubuntu -m -s /bin/bash -p '*' ubuntu
RUN usermod -G docker ubuntu

RUN echo "ubuntu ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN echo "Defaults !requiretty" >> /etc/sudoers
RUN install -d -m 0700 -o ubuntu -g ubuntu /home/ubuntu/.ssh

COPY .kitchen/docker_id_rsa /root/.ssh/id_rsa
COPY .kitchen/docker_id_rsa /home/ubuntu/.ssh/id_rsa
COPY .kitchen/docker_id_rsa.pub /home/ubuntu/.ssh/id_rsa.pub
RUN chmod 0600 /home/ubuntu/.ssh/id_rsa /root/.ssh/id_rsa

RUN install -d -m 0700 -o ubuntu -g ubuntu /home/ubuntu/.ssh
COPY .ssh/authorized_keys /home/ubuntu/.ssh/authorized_keys
RUN cat /home/ubuntu/.ssh/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys

RUN chown -R ubuntu /home/ubuntu/.ssh
RUN chmod 0600 /home/ubuntu/.ssh/authorized_keys

RUN chown -R root:root /root/.ssh
