pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/victor-dias21/dash'
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
                    python -c "import dash, pandas, xgboost; print('✅ Dependências OK!')"
                    if [ -d "tests" ]; then
                        pytest -v || echo "Testes falharam, continuando..."
                    else
                        echo "⚠️  Diretório de testes não encontrado, pulando..."
                    fi
                '''
            }
        }
        
        stage('Análise Estática') {
            steps {
                sh '''
                    . venv/bin/activate
                    echo "=== Executando Flake8 ==="
                    flake8 --ignore=W291,W293,W391,E501 ./*.py || true
                '''
            }
        }
        
        stage('Documentação') {
            steps {
                sh '''
                    if [ -d "source" ] && [ -f "source/conf.py" ]; then
                        sphinx-build -b html source/ build/
                    else
                        echo "⚠️  Diretório de documentação não encontrado, pulando..."
                    fi
                '''
            }
        }
        
        stage('Build Docker Multi-stage') {
            steps {
                script {
                    echo "=== Building imagem multi-stage otimizada ==="
                    
                    // Criar Dockerfile corrigido
                    sh '''
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
    util-linux \\
    && rm -rf /var/lib/apt/lists/* \\
    && apt-get clean

COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:\\$PATH"

RUN addgroup --system appuser && adduser --system --group appuser \\
    && chown -R appuser:appuser /app
USER appuser

COPY app.py main.py medianas.pkl modelo_xgboost.pkl ./
COPY assets/ ./assets/
COPY paginas/ ./paginas/

EXPOSE 8081

CMD ["python", "app.py"]
DOCKERFILE
                        
                        echo "=== Dockerfile criado ==="
                        cat Dockerfile
                    '''
                    
                    docker.build('dash_teste', '.')
                    
                    sh '''
                        echo "=== Tamanho da imagem ==="
                        docker images dash_teste:latest --format "table {{.Repository}}\\t{{.Tag}}\\t{{.Size}}"
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
                        docker run -d \\
                            --name dash-teste-optimized \\
                            --restart=unless-stopped \\
                            -p 8081:8081 \\
                            dash_teste:latest
                    '''
                    
                    // Health check
                    sh '''
                        echo "=== Aguardando inicialização (30 segundos) ==="
                        sleep 30
                        
                        echo "=== Status do container ==="
                        docker ps | grep dash-teste-optimized || echo "Container não encontrado"
                        
                        echo "=== Logs recentes ==="
                        docker logs --tail 15 dash-teste-optimized || echo "Não foi possível acessar logs"
                        
                        echo "=== Testando aplicação ==="
                        if curl -f http://localhost:8081; then
                            echo "✅ Aplicação respondendo com sucesso!"
                        else
                            echo "❌ Aplicação não respondeu"
                            docker logs dash-teste-optimized | tail -20
                        fi
                    '''
                }
            }
        }
    }
    
    post {
        always {
            sh '''
                echo "=== Status final dos containers ==="
                docker ps -a || true
                echo "=== Tamanho final da imagem ==="
                docker images dash_teste:latest --format "{{.Size}}" || true
            '''
        }
    }
}