# syntax=docker/dockerfile:1

FROM python:3.12-slim AS builder

WORKDIR /build

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

COPY requirements.txt .

RUN pip wheel --wheel-dir /wheels -r requirements.txt


FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

LABEL org.opencontainers.image.title="devops-intern-task" \
      org.opencontainers.image.description="Flask application for DevOps Intern Task"

RUN groupadd --system app \
    && useradd --system --gid app --no-create-home app

WORKDIR /app

COPY --from=builder /wheels /wheels
COPY requirements.txt .

RUN pip install --no-cache-dir \
        --no-index \
        --find-links=/wheels \
        -r requirements.txt \
    && rm -rf /wheels

COPY --chown=app:app app.py .

USER app

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8080/health', timeout=2).status == 200 else 1)"

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--access-logfile", "-", "app:app"]