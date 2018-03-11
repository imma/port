FROM ubuntu

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y rsync sudo

RUN groupadd -g 1000 ubuntu
RUN useradd -m -s /bin/bash -g ubuntu -u 1000 ubuntu
RUN install -d -m 0700 -o ubuntu -g ubuntu /home/ubuntu/.ssh
RUN echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu
