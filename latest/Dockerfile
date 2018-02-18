FROM imma/ubuntu

RUN rm -rf /root/.ssh

RUN mkdir -p /home/ubuntu/.ssh
COPY .ssh/authorized_keys /home/ubuntu/.ssh/authorized_keys
RUN chown -R ubuntu /home/ubuntu/.ssh
RUN chmod 0700 /home/ubuntu/.ssh
RUN chmod 0600 /home/ubuntu/.ssh/authorized_keys

VOLUME /home
