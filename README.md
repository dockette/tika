<h1 align=center>Dockette / Tika</h1>

<p align=center>
   🎁 Apache Tika server with OCR on and extra Tesseract languages.
</p>

<p align=center>
🕹 <a href="https://f3l1x.io">f3l1x.io</a> | 💻 <a href="https://github.com/f3l1x">f3l1x</a> | 🐦 <a href="https://twitter.com/xf3l1x">@xf3l1x</a>
</p>

<p align=center>
  <a href="https://github.com/dockette/tika/actions"><img src="https://github.com/dockette/tika/actions/workflows/docker.yml/badge.svg"></a>
  <a href="https://hub.docker.com/r/dockette/tika/"><img src="https://badgen.net/docker/pulls/dockette/tika"></a>
  <a href="https://github.com/sponsors/f3l1x"><img src="https://badgen.net/badge/sponsor/donations/F96854"></a>
  <a href="https://github.com/orgs/dockette/discussions"><img src="https://badgen.net/badge/support/discussions/blue"></a>
</p>

------

[Apache Tika](https://tika.apache.org) server that extracts text and metadata from PDF, Office, images and 1000+ other
formats. The upstream `apache/tika:<version>-full` image has only 7 OCR languages and does not OCR scanned PDFs. This
image adds 20 languages and turns OCR on.

## Features

- Apache Tika `3.3.1.0` on the upstream `-full` image (Tesseract 5, GDAL, ImageMagick)
- 20 Tesseract languages and `osd`, see the table below
- OCR on by default, tuned for scanned PDFs ([tika-config.xml](tika-config.xml))
- Prometheus JVM metrics on `:9464/metrics` ([jmx_exporter](https://github.com/prometheus/jmx_exporter) `1.7.0`)
- Healthcheck on `/version`
- Entrypoint, user `35002:35002` and port `9998` are the same as upstream

| Code      | Language            | Code      | Language   |
|-----------|---------------------|-----------|------------|
| `ara`     | Arabic              | `jpn`     | Japanese   |
| `ces`     | Czech               | `kor`     | Korean     |
| `chi_sim` | Chinese simplified  | `nld`     | Dutch      |
| `chi_tra` | Chinese traditional | `pol`     | Polish     |
| `deu`     | German              | `por`     | Portuguese |
| `eng`     | English             | `rus`     | Russian    |
| `fra`     | French              | `slk`     | Slovak     |
| `hin`     | Hindi               | `spa`     | Spanish    |
| `hun`     | Hungarian           | `tur`     | Turkish    |
| `ita`     | Italian             | `ukr`     | Ukrainian  |

## Usage

```sh
docker run --rm -it -p 9998:9998 -p 9464:9464 dockette/tika:latest
```

```sh
# Text
curl -T document.pdf -H 'Accept: text/plain' http://localhost:9998/tika

# OCR in another language (default is eng), or in more languages
curl -T scan.pdf -H 'Accept: text/plain' -H 'X-Tika-OCRLanguage: slk' http://localhost:9998/tika
curl -T scan.pdf -H 'Accept: text/plain' -H 'X-Tika-OCRLanguage: eng+ces' http://localhost:9998/tika

# OCR every page, also when the PDF has a text layer
curl -T doc.pdf -H 'Accept: text/plain' -H 'X-Tika-PDFocrStrategy: ocr_and_text_extraction' http://localhost:9998/tika

# Text and metadata of every embedded document, as JSON
curl -T archive.zip http://localhost:9998/rmeta/text
```

## Configuration

The image runs with [tika-config.xml](tika-config.xml):

- `ocrStrategy=auto`: read the text layer, OCR only pages without text
- `ocrDPI=250`: measured on scanned invoices; the Tika default `300` gave worse results
- `extractInlineImages=false`: `true` OCRs each page twice and duplicates the text
- `language=eng`, `pageSegMode=1`, `timeoutSeconds=300`

To use your own file, mount it. Copy the `<server>` block from ours to keep the metrics.

```sh
docker run --rm -it -p 9998:9998 -v $(pwd)/tika-config.xml:/tika-config.xml:ro dockette/tika:latest
```

Arguments after the image name replace the default `--config /tika-config.xml` and go to `TikaServerCli -h 0.0.0.0`.

Set the heap in `forkedJvmArgs`, for example `<arg>-Xmx4g</arg>`. Without it, the JVM sizes the heap from host RAM. Do
not use `JAVA_TOOL_OPTIONS`: it applies to both JVMs.

## Metrics

Tika parses in a child JVM (`TikaServerProcess`). The child loads the jmx_exporter agent and serves `jvm_*` and
`process_*` metrics on port `9464`. Tika has no metrics of its own, so there are no per-request metrics. When the child
restarts (OOM or timeout), `process_start_time_seconds` changes.

## Versions

| Version | Release |
|---------|---------|
| `dockette/tika:3.3.1.0-YYYY.MM.DD` | release `YYYY.MM.DD` |
| `dockette/tika:3.3.1.0` | latest release |
| `dockette/tika:YYYY.MM.DD` | release `YYYY.MM.DD` |
| `dockette/tika:latest` | latest build of `master` |

All versions build on `apache/tika:3.3.1.0-full`. Releases are listed on [GitHub](https://github.com/dockette/tika/releases).

## Development

```sh
make build          # build the image
make test           # check languages and config
make test-docker    # start the server and OCR a scanned PDF
make run            # run the server on port 19998
make shell          # open a shell in the image
make push           # build and push linux/amd64 and linux/arm64
make version        # print VERSION
make release        # set today's date in VERSION
```

## Maintenance

See [how to contribute](https://github.com/dockette/.github/blob/master/CONTRIBUTING.md) to this package. Consider to
[support](https://github.com/sponsors/f3l1x) **f3l1x**. Thank you for using this package.
