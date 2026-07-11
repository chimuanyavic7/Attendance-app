FROM python:3.11.13-slim-bookworm AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade \
    pip==25.1.1 \
    setuptools==78.1.1 \
    wheel==0.46.2

COPY requirements.txt .

RUN pip install \
    --prefix=/install \
    --no-cache-dir \
    -r requirements.txt


FROM python:3.11.13-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN useradd --create-home --uid 10001 appuser

COPY --from=builder /install /usr/local

COPY --chown=appuser:appuser . .
COPY --chown=appuser:appuser entrypoint.sh /entrypoint.sh

RUN sed -i 's/\r$//' /entrypoint.sh && \
    chmod +x /entrypoint.sh

USER appuser

EXPOSE 5000

ENTRYPOINT ["/entrypoint.sh"]

CMD ["gunicorn", "--workers=3", "--bind=0.0.0.0:5000", "app:app"]