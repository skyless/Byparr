FROM python:3.12-alpine

# Update and install dependencies
RUN apk update && apk upgrade && \
    apk add --no-cache --virtual .build-deps \
    alpine-sdk \
    curl \
    wget \
    unzip \
    gnupg && \
    apk add --no-cache \
    xvfb \
    x11vnc \
    fluxbox \
    xterm \
    libffi-dev \
    openssl-dev \
    zlib-dev \
    bzip2-dev \
    readline-dev \
    git \
    nss \
    freetype \
    freetype-dev \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    chromium \
    chromium-chromedriver \
    py3-pip

# Install Poetry through pip
RUN pip install --no-cache-dir poetry

WORKDIR /app
EXPOSE 8191

# Environment variables
ENV \
    DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    DISPLAY=:0

# Install Python dependencies using Poetry
COPY pyproject.toml poetry.lock ./
RUN poetry install --no-root

# Copy and execute additional scripts
COPY fix_nodriver.py ./
RUN . /app/.venv/bin/activate && python fix_nodriver.py

COPY . .

# Ensure scripts are executable
RUN chmod +x ./run_vnc.sh ./entrypoint.sh

# Run tests and setup VNC environment
RUN ./run_vnc.sh && . /app/.venv/bin/activate && poetry run pytest

CMD ["./entrypoint.sh"]

# Clean up build dependencies to reduce image size
RUN apk del .build-deps
