FROM ubuntu

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y rsync sudo

RUN groupadd -g 1000 ubuntu
RUN useradd -m -s /bin/bash -g ubuntu -u 1000 ubuntu
RUN install -d -m 0700 -o ubuntu -g ubuntu /home/ubuntu/.ssh
RUN echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu

RUN mkdir /sync
RUN chown ubuntu:ubuntu /sync

USER ubuntu
WORKDIR /home/ubuntu

RUN sudo apt-get install -y jq locales
RUN sudo locale-gen en_US.UTF-8
RUN sudo dpkg-reconfigure --frontend=noninteractive locales
RUN sudo update-locale LANG=en_US.UTF-8

RUN sudo groupadd -g 497 docker
RUN sudo usermod -G docker ubuntu

RUN sudo apt-get install -y vim-nox git python
