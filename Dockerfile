# Estágio de build
FROM python:3.10-slim as builder

WORKDIR /app

# Instalar dependências de compilação
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

COPY requirements.txt .

# Criar virtualenv
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Instalar dependências
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Estágio final
FROM python:3.10-slim

WORKDIR /app

# Instalar dependências de runtime
RUN apt-get update && apt-get install -y \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copiar virtualenv
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copiar apenas arquivos necessários
COPY app.py main.py medianas.pkl modelo_xgboost.pkl ./
COPY assets/ ./assets/
COPY paginas/ ./paginas/

# Criar usuário não-root
RUN groupadd -r appuser && useradd -r -g appuser appuser \
    && chown -R appuser:appuser /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8081', timeout=5)"

EXPOSE 8081

# Usar JSON format para evitar warnings
CMD ["python", "app.py"]