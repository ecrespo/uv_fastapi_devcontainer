# Primera etapa: compilación y creación de la aplicación
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder

# Configuración de entorno
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy

# Directorio de trabajo para la aplicación
WORKDIR /app

# Montaje de caché para acelerar las instalaciones futuras y bind de los archivos necesarios
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev

# Agregamos el contenido de la aplicación
ADD . /app

# Copiamos los archivos necesarios
COPY app.py /app/
COPY run.py /app/

# Instalación de las dependencias necesarias
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

# Segunda etapa: imagen final
FROM python:3.12-slim-bookworm

# Directorio de trabajo para la aplicación
WORKDIR /app

# Copiamos las dependencias instaladas desde la imagen "builder"
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages

# Copia el directorio completo de la aplicación desde la imagen "builder"
COPY --from=builder /app /app

# Configuramos el PATH para incluir el virtual environment
ENV PATH="/app/.venv/bin:$PATH"

# Ejecuta la aplicación FastAPI de forma predeterminada
CMD ["python3", "run.py"]