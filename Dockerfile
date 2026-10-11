ARG TIKA_VERSION=3.3.1.0

FROM apache/tika:${TIKA_VERSION}-full

LABEL maintainer="sulcmil@gmail.com"

# The base image runs as 35002:35002. apt needs root.
USER root

# TESSERACT LANGUAGES ##########################################################
# Upstream ships deu eng fra ita jpn osd spa. Without a language pack, OCR
# returns garbage instead of an error. This adds the rest of the top 20.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        tesseract-ocr-ara \
        tesseract-ocr-ces \
        tesseract-ocr-chi-sim \
        tesseract-ocr-chi-tra \
        tesseract-ocr-hin \
        tesseract-ocr-hun \
        tesseract-ocr-kor \
        tesseract-ocr-nld \
        tesseract-ocr-pol \
        tesseract-ocr-por \
        tesseract-ocr-rus \
        tesseract-ocr-slk \
        tesseract-ocr-tur \
        tesseract-ocr-ukr && \
    rm -rf /var/lib/apt/lists/*

# JMX EXPORTER #################################################################
# Prometheus metrics of the forked Tika JVM on :9464/metrics. tika-config.xml
# loads the agent through forkedJvmArgs, so only the child JVM exports.
ARG JMX_EXPORTER_VERSION=1.7.0
ARG JMX_EXPORTER_SHA256=0ad843261c567d1924a017d542e14c40f2afff523d940c25ee000742fde4b3a9
ADD --checksum=sha256:${JMX_EXPORTER_SHA256} \
    https://github.com/prometheus/jmx_exporter/releases/download/${JMX_EXPORTER_VERSION}/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar \
    /opt/jmx_exporter/jmx_prometheus_javaagent.jar
COPY jmx-exporter.yaml /opt/jmx_exporter/config.yaml
# ADD of a URL is 0600 root; the server runs as 35002.
RUN chmod 0755 /opt/jmx_exporter && chmod 0644 /opt/jmx_exporter/*

EXPOSE 9464

# CONFIG #######################################################################
# OCR is off for PDFs without a config. The upstream entrypoint appends CMD to
# `TikaServerCli -h 0.0.0.0`.
COPY tika-config.xml /tika-config.xml

USER 35002:35002

CMD ["--config", "/tika-config.xml"]

# HEALTHCHECK ##################################################################
# No curl in the image; wget is present.
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:9998/version || exit 1
