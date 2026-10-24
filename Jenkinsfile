pipeline {
    agent any

    environment {
        
        PATH = "/usr/local/bin:/usr/bin:/bin:${env.PATH}"
        
        DOCKER_HUB_USER = "shivanshks06"
        IMAGE_NAME      = "ai-resume-analyzer"
        IMAGE_TAG       = "${env.BUILD_NUMBER}"
        
        DOCKER_HUB_CREDENTIALS = "dockerhub-credentials"
    }

    stages {
        stage('Clone Repository') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Clean Space Before Build') {
            steps {
                echo 'Reclaiming disk space before building...'
                sh '''
                    # Aggressively remove unused build cache and dangling images
                    docker system prune -af || true
                    docker builder prune -af || true
                    df -h /
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}..."
                sh "docker build -t ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} -t ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest ."
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo 'Logging in and pushing image to Docker Hub...'
                withCredentials([usernamePassword(credentialsId: "${DOCKER_HUB_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                    sh "docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest"
                }
            }
        }

        stage('Deploy Application') {
            steps {
                echo 'Deploying application with Docker Compose...'
                sh 'docker compose down || true'
                sh 'docker compose up -d'
            }
        }
    }

    post {
        always {
            echo 'Post-build cleanup...'
            sh '''
                docker image prune -f || true
                docker builder prune -f || true
            '''
        }
        success {
            echo 'Pipeline succeeded! Image pushed to Docker Hub and application deployed.'
        }
        failure {
            echo 'Pipeline failed. Check Jenkins logs for details.'
        }
    }
}
