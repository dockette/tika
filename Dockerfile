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
