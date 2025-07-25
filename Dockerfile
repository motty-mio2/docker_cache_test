FROM ghcr.io/astral-sh/uv:python3.11-bookworm-slim AS req

WORKDIR /io

RUN --mount=type=bind,source=./pyproject.toml,target=/io/pyproject.toml \
    --mount=type=bind,source=./uv.lock,target=/io/uv.lock \
    uv export --no-dev --no-hashes --no-emit-project --output-file /requirements.txt

FROM python:3.11-slim-bookworm AS base

RUN \
    --mount=type=cache,target=/var/lib/apt/lists \
    --mount=type=cache,target=/var/cache/apt/archives \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    openssh-client \
    ca-certificates

RUN --mount=type=bind,from=req,source=/requirements.txt,target=/requirements.txt \
    pip install --no-cache-dir -r /requirements.txt

FROM base AS app

WORKDIR /app
ENV PYTHONPATH="/app/src/"

COPY ./src /app/src

RUN --mount=type=bind,source=./pyproject.toml,target=/app/pyproject.toml \
    --mount=type=bind,source=./README.md,target=/app/README.md \
    pip install --no-cache-dir /app


RUN --mount=type=ssh \
    mkdir -p /root/.ssh && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts && \
    ssh -T git@github.com || true

CMD ["python", "-m", "docker_cache_test.main"]