ARG ELK_VERSION

# https://github.com/elastic/elastic-agent
FROM docker.elastic.co/beats/elastic-agent:${ELK_VERSION}

USER root
ADD bside-2.0.0.tar /tmp/bside
RUN sh /tmp/bside/init.sh && apt-get install -y jq

USER elastic-agent
# TODO Add healthcheck
#COPY scripts/docker-healthcheck .
#HEALTHCHECK CMD sh ./docker-healthcheck
