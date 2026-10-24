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

## Prologue

[Apache Tika](https://tika.apache.org) extracts text and metadata from PDF, Office, images and 1000+ other formats.

The upstream `apache/tika:<version>-full` image has Tesseract, but only 7 languages. Without a language pack, OCR returns
garbage instead of an error. Without a config, Tika does not OCR scanned PDFs at all. This image fixes both.

**Features**

- Apache Tika `3.3.1.0` (upstream `-full` image: Tesseract 5, GDAL, ImageMagick)
- Tesseract languages: ara, ces, chi_sim, chi_tra, deu, eng, fra, hin, hun, ita, jpn, kor, nld, pol, por, rus, slk, spa, tur, ukr + `osd`
- OCR on by default, tuned for scanned PDFs (`tika-config.xml`)
- Prometheus JVM metrics of the forked Tika process on `:9464/metrics` ([jmx_exporter](https://github.com/prometheus/jmx_exporter) `1.7.0`)
- Healthcheck on `/version`, done with `wget`
- Entrypoint, user (`35002`) and exposed port (`9998`) are inherited from upstream

**Languages**

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

Extract text:

```sh
curl -T document.pdf -H 'Accept: text/plain' http://localhost:9998/tika
```

OCR in a specific language (default is `eng`):

```sh
curl -T scan.pdf -H 'Accept: text/plain' -H 'X-Tika-OCRLanguage: slk' http://localhost:9998/tika
curl -T scan.pdf -H 'Accept: text/plain' -H 'X-Tika-OCRLanguage: eng+ces' http://localhost:9998/tika
```

Force OCR on every page, also when the PDF has a text layer:

```sh
curl -T doc.pdf -H 'Accept: text/plain' -H 'X-Tika-PDFocrStrategy: ocr_and_text_extraction' http://localhost:9998/tika
```

Text and metadata of every embedded document as JSON:

```sh
curl -T archive.zip http://localhost:9998/rmeta/text
```

With your own configuration file:

```sh
docker run \
    --rm \
    -it \
    -p 9998:9998 \
    -v $(pwd)/tika-config.xml:/tika-config.xml:ro \
    dockette/tika:latest
```

## Configuration

The default `CMD` is `--config /tika-config.xml`. The arguments are appended to `TikaServerCli -h 0.0.0.0`. See
[tika-config.xml](tika-config.xml):

- `ocrStrategy=auto` - read the text layer, OCR only pages with no text
- `ocrDPI=250` - measured on scanned invoices; Tika's default `300` gave worse results
- `extractInlineImages=false` - `true` OCRs each page twice and duplicates the text
- `language=eng`, `pageSegMode=1`, `timeoutSeconds=300`

## Metrics

`TikaServerCli` forks a child JVM (`TikaServerProcess`) that does the parsing. The child loads the jmx_exporter agent
through `forkedJvmArgs` in `tika-config.xml` and serves `jvm_*` and `process_*` metrics on port `9464`. Tika has no
MBeans of its own, so there are no per-request metrics. When the child restarts (OOM or timeout),
`process_start_time_seconds` changes.

If you mount your own `tika-config.xml`, copy the `<server>` block to keep the metrics.

## Memory

Set the heap of the child JVM in `forkedJvmArgs`, for example `<arg>-Xmx4g</arg>`. Without a limit, the JVM sizes the
heap from host RAM. Do not use `JAVA_TOOL_OPTIONS` for the heap: it applies to both JVMs.

## Tags

| Tag       | Upstream                   |
|-----------|----------------------------|
| `latest`  | `apache/tika:3.3.1.0-full` |
| `3.3.1.0` | `apache/tika:3.3.1.0-full` |

## Versions

The release version is the date in [`VERSION`](VERSION). CI pushes `latest` also as `dockette/tika:<VERSION>`.
To release, run `make release`, commit and push to `master`.

## User

Default user is `35002:35002`, same as upstream.

## Development

```sh
make build          # build the image
make test           # check languages and config
make test-docker    # start the server and OCR a scanned PDF
make run            # run the server on port 19998
make shell          # open a shell in the image
make push           # build and push linux/amd64 and linux/arm64
make version        # print VERSION
make release        # set VERSION to today's date
```

Build against another Tika release:

```sh
make build TIKA_VERSION=3.2.3.0
```

## Maintenance

See [how to contribute](https://github.com/dockette/.github/blob/master/CONTRIBUTING.md) to this package. Consider to
[support](https://github.com/sponsors/f3l1x) **f3l1x**. Thank you for using this package.
