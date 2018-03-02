FROM centos:7.4.1708

ENV container docker

RUN yum update -y && yum install -y sudo openssh-server openssh-clients which curl nc

RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ''

RUN groupadd -g 1000 ubuntu
RUN useradd -u 1000 -g ubuntu -d /home/ubuntu -m -s /bin/bash -p '*' ubuntu

RUN echo "ubuntu ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN echo "Defaults !requiretty" >> /etc/sudoers
RUN install -d -m 0700 -o ubuntu -g ubuntu /home/ubuntu/.ssh

COPY .kitchen/docker_id_rsa.pub /home/ubuntu/.ssh/authorized_keys
COPY .kitchen/docker_id_rsa /home/ubuntu/.ssh/id_rsa
COPY .kitchen/docker_id_rsa /root/.ssh/id_rsa

RUN chown -R ubuntu /home/ubuntu/.ssh
RUN chmod 0600 /home/ubuntu/.ssh/authorized_keys
RUN chmod 0600 /home/ubuntu/.ssh/id_rsa

RUN chown -R root:root /root/.ssh
RUN chmod 0600 /root/.ssh/id_rsa
