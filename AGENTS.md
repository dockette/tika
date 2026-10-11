# AGENTS.md

Apache Tika server Docker image with OCR, published as `dockette/tika`.

## Writing style

- Write in ASD-STE100 (Simplified Technical English).
- Follow Zinsser's four principles of quality writing:
  1. Simplicity
  2. Brevity
  3. Clarity
  4. Humanity

## Conventions

- The image adds Tesseract language packs and `tika-config.xml` to
  `apache/tika:<version>-full`. Keep it that way.
- Do not override the upstream entrypoint, user or exposed port. Arguments go
  in `CMD`; the entrypoint appends them to `TikaServerCli -h 0.0.0.0`.
- The upstream version is pinned in `ARG TIKA_VERSION` in the `Dockerfile`.
  The default value must build correctly without any `--build-arg`, because the
  shared workflow in `dockette/.github` cannot pass build arguments.
- A version bump touches three places: the `ARG` default, `TIKA_VERSION` in the
  `Makefile`, and the `tag` matrix in `.github/workflows/docker.yml`.
- A language change touches the `Dockerfile`, `TIKA_LANGS` in the `Makefile`
  and the table in `README.md`.
- `tika-config.xml` values are measured. Read its comments before you change
  them; `extractInlineImages` must stay `false`.
- CI builds every branch. Only master is pushed to Docker Hub.
- `make test` checks the image contents. `make test-docker` starts the server
  and OCRs `tests/fixtures/scanned-sk.pdf`.
- Run `make build test test-docker` before you commit.
