FROM python:3.9-slim

SHELL ["/bin/bash", "-c"]

# Install basic tools
RUN set -euo pipefail; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      libmagic1 \
      zip \
      unzip \
      gcc \
      python3-dev \
      xz-utils; \
    rm -rf /var/lib/apt/lists/*

# Install python tools
RUN set -euo pipefail; \
    pip3 install --upgrade \
      pip \
      pipenv \
      pip-audit \
      setuptools>=65.5.1 \
      mypy \
      types-requests \
      black \
      pytest \
      coverage \
      tavern \
      msgpack \
      falcon \
      serverless-wsgi \
      requests \
      responses \
      prance \
      pylint \
      boto3 \
      pycognito

ENV COVERAGE_FILE /opt/app/output/coverage/.coverage
