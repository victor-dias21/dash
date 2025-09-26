# Estágio 1: Builder - para compilar dependências
FROM python:3.10-slim as builder

WORKDIR /app

# Instalar apenas dependências de compilação necessárias
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

COPY requirements.txt .

# Criar virtualenv e instalar dependências
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Estágio 2: Runtime - imagem final mínima
FROM python:3.10-slim

WORKDIR /app

# Instalar apenas dependências de runtime
RUN apt-get update && apt-get install -y \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && rm -rf /var/cache/apt/* /tmp/* /var/tmp/*

# Copiar virtualenv do estágio builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Criar usuário não-root para segurança
RUN groupadd -r appuser && useradd -r -g appuser appuser \
    && chown -R appuser:appuser /app
USER appuser

# Copiar apenas arquivos necessários da aplicação
COPY --chown=appuser:appuser app.py main.py medianas.pkl modelo_xgboost.pkl ./
COPY --chown=appuser:appuser assets/ ./assets/
COPY --chown=appuser:appuser paginas/ ./paginas/

EXPOSE 8081

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8081', timeout=5)"

CMD ["python", "app.py"]