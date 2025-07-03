FROM ubuntu:24.04
LABEL maintainer="flaskfarm <flaskfarm@gmail.com>"

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ                  Asia/Seoul
ENV LANG                ko_KR.UTF-8
ENV LANGUAGE            ko_KR.UTF-8
ENV LC_ALL              ko_KR.UTF-8
COPY ./export.sh /root
COPY ./run.sh /root
COPY ./setff.sh /root
RUN apt -y update && \
    apt -y install locales && \
    locale-gen ko_KR.UTF-8 && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt -y install tzdata && \
    apt -y install git python3.10 python3-dev python3-pip curl redis fuse unzip socat && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    pip config set global.cache-dir false && \
    python -m pip --no-cache-dir install --upgrade pip && \
    pip --no-cache-dir install --upgrade setuptools wheel && \
    pip --no-cache-dir install --upgrade flaskfarm redis celery && \
    mkdir /data && \
    chmod +x /root/export.sh && \
    chmod +x /root/run.sh && \
    chmod +x /root/setff.sh && \
    /root/setff.sh \
    rm -rf /var/lib/apt/lists/*

WORKDIR /data
EXPOSE 9999
ENTRYPOINT [ "/root/run.sh" ]
