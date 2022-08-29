FROM alpine:3.14

RUN mkdir -p /etc/docker/
RUN echo "{" > /etc/docker/daemon.json \
    && echo "	\"insecure-registries\" : [ \"https://harbor.cloud.c3.furg.br\" ]" >> /etc/docker/daemon.json \
    && echo "}" >> /etc/docker/daemon.json

RUN cat /etc/docker/daemon.json

COPY daemon.json /etc/docker/daemon.json
ADD https://github.com/mikefarah/yq/releases/download/v4.12.1/yq_linux_amd64 /usr/local/bin/yq
RUN chmod +x /usr/local/bin/yq

ADD https://github.com/docker/buildx/releases/download/v0.5.1/buildx-v0.5.1.linux-amd64 /usr/local/bin/buildx
RUN chmod +x /usr/local/bin/buildx

ADD https://github.com/openfaas/faas-cli/releases/download/0.13.13/faas-cli /usr/local/bin/faas-cli
RUN chmod +x /usr/local/bin/faas-cli

RUN apk add bash git docker
RUN apk add openrc --no-cache

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["rc-service docker restart"]

ENTRYPOINT [ "/entrypoint.sh" ]
