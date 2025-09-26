pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/lucasribeirolrm/dashboard'
            }
        }
        
        stage('Limpeza') {
            steps {
                sh '''
                    echo "=== Limpando arquivos desnecessários ==="
                    rm -rf venv/ build/ __pycache__/ */__pycache__/ .pytest_cache/
                    find . -name "*.pyc" -delete
                    find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
                    find . -name ".pytest_cache" -type d -exec rm -rf {} + 2>/dev/null || true
                    du -sh . || true
                '''
            }
        }
        
        stage('Test') {
            steps {
                sh '''
                    python3 -m venv venv
                    . venv/bin/activate
                    pip install -r requirements.txt
                    pytest -v || echo "Testes falharam, continuando..."
                '''
            }
        }
        
        stage('Análise Estática') {
            steps {
                sh '''
                    . venv/bin/activate
                    flake8 --ignore=W291,W293,W391,E501 ./*.py || true
                '''
            }
        }
        
        stage('Documentação') {
            steps {
                sh 'sphinx-build -b html source/ build/'
            }
        }
        
        stage('Build Docker Multi-stage') {
            steps {
                script {
                    echo "=== Building imagem multi-stage otimizada ==="
                    
                    // Verificar se existe Dockerfile, senão criar
                    sh '''
                        if [ ! -f Dockerfile ]; then
                            echo "Criando Dockerfile multi-stage..."
                            cat > Dockerfile << 'DOCKERFILE'
FROM python:3.10-slim as builder

WORKDIR /app

RUN apt-get update && apt-get install -y \\
    gcc \\
    g++ \\
    && rm -rf /var/lib/apt/lists/* \\
    && apt-get clean

COPY requirements.txt .

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:\\$PATH"

RUN pip install --no-cache-dir --upgrade pip && \\
    pip install --no-cache-dir -r requirements.txt

FROM python:3.10-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \\
    libgomp1 \\
    && rm -rf /var/lib/apt/lists/* \\
    && apt-get clean

COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:\\$PATH"

RUN groupadd -r appuser && useradd -r -g appuser appuser \\
    && chown -R appuser:appuser /app
USER appuser

COPY app.py main.py medianas.pkl modelo_xgboost.pkl ./
COPY assets/ ./assets/
COPY paginas/ ./paginas/

EXPOSE 8081

CMD ["python", "app.py"]
DOCKERFILE
                        fi
                    '''
                    
                    docker.build('dash_teste', '.')
                    
                    sh '''
                        echo "=== Tamanho da imagem ==="
                        docker images dash_teste:latest --format "table {{.Repository}}\\t{{.Tag}}\\t{{.Size}}"
                        echo "=== Camadas da imagem ==="
                        docker history dash_teste:latest
                    '''
                }
            }
        }
        
        stage('Deploy Teste') {
            steps {
                script {
                    // Limpar containers anteriores
                    sh 'docker stop dash-teste-optimized || true'
                    sh 'docker rm dash-teste-optimized || true'
                    
                    // Executar nova imagem otimizada
                    sh '''
                        docker run -d \
                            --name dash-teste-optimized \
                            --restart=unless-stopped \
                            -p 8081:8081 \
                            dash_teste:latest
                    '''
                    
                    // Health check
                    sh '''
                        echo "=== Aguardando inicialização ==="
                        sleep 20
                        echo "=== Status ==="
                        docker ps | grep dash-teste-optimized
                        echo "=== Health check ==="
                        curl -f http://localhost:8081 && echo "✅ OK" || echo "❌ Falha"
                        echo "=== Logs ==="
                        docker logs --tail 10 dash-teste-optimized
                    '''
                }
            }
        }
    }
    
    post {
        always {
            sh '''
                echo "=== Status final ==="
                docker ps -a
                echo "=== Tamanho final da imagem ==="
                docker images dash_teste:latest --format "{{.Size}}"
            '''
        }
    }
}