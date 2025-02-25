# Multistage docker file


FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder
ENV UV_COMPLIE_BYTECODE=1 UV_LINK_MODE=copy 


ENV UV_PYTHON_DOWNLOADS=0

WORKDIR /app
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev

ADD . /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev


#using final image without uv
FROM python:3.12-slim-bookworm

#copy application from builder
COPY --from=builder --chown=app:app /app /app

#place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"

#run the FastAPI application by default
CMD ["fastapi", "run", "--host", "0.0.0.0", "--port", "5000", "/app/api.py"]