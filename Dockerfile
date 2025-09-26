FROM python:3.10-slim

WORKDIR /app

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Copiar apenas arquivos necessários
COPY app.py main.py medianas.pkl modelo_xgboost.pkl ./
COPY assets/ ./assets/
COPY paginas/ ./paginas/

EXPOSE 8081

CMD ["python", "app.py"]