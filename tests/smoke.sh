#!/usr/bin/env sh
# Smoke test for the image. Usage: IMAGE=dockette/tika:latest PORT=19998 ./tests/smoke.sh
set -eu

IMAGE="${IMAGE:-dockette/tika:latest}"
PORT="${PORT:-19998}"
NAME="${NAME:-tika-smoke}"
TIMEOUT="${TIMEOUT:-120}"
FIXTURES="$(cd "$(dirname "$0")/fixtures" && pwd)"

cleanup() {
    docker rm -f "$NAME" > /dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

cleanup

echo "> start ${IMAGE} on port ${PORT}"
docker run -d --name "$NAME" -p "${PORT}:9998" "$IMAGE" > /dev/null

echo "> wait for http://127.0.0.1:${PORT}/version"
i=0
until curl -fsS "http://127.0.0.1:${PORT}/version" > /dev/null 2>&1; do
    i=$((i + 1))
    if [ "$i" -ge "$TIMEOUT" ]; then
        echo "! server did not start" >&2
        docker logs "$NAME" >&2
        exit 1
    fi
    sleep 1
done
curl -fsS "http://127.0.0.1:${PORT}/version"
echo

echo "> OCR of a scanned PDF (no text layer), slk"
out="$(curl -fsS -T "${FIXTURES}/scanned-sk.pdf" \
    -H 'Accept: text/plain' \
    -H 'X-Tika-OCRLanguage: slk' \
    "http://127.0.0.1:${PORT}/tika")"
echo "$out" | grep -q "Faktúra za služby" \
    || { echo "! OCR did not return the Slovak text" >&2; echo "$out" >&2; exit 1; }

echo "> text is not duplicated"
[ "$(echo "$out" | grep -c "Faktúra za služby")" -eq 1 ] \
    || { echo "! OCR text is duplicated (extractInlineImages?)" >&2; exit 1; }

echo "> docker healthcheck"
i=0
until [ "$(docker inspect --format '{{.State.Health.Status}}' "$NAME")" = "healthy" ]; do
    i=$((i + 1))
    if [ "$i" -ge "$TIMEOUT" ]; then
        echo "! container did not become healthy" >&2
        docker inspect --format '{{json .State.Health}}' "$NAME" >&2
        exit 1
    fi
    sleep 1
done

echo "> ok"
