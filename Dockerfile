FROM imma/ubuntu

RUN install -d -m 0700 -o ubuntu -g ubuntu /home/ubuntu/.ssh
COPY .ssh/authorized_keys /home/ubuntu/.ssh/authorized_keys
RUN chown -R ubuntu /home/ubuntu/.ssh
RUN chmod 0600 /home/ubuntu/.ssh/authorized_keys
