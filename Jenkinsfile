pipeline {
    agent any  // Runs on any available agent (your EC2 with Docker/Jenkins)

    environment {
        // Docker image details
        DOCKERHUB_REPO = 'yourusername/your-app-name'  // CHANGE THIS
        DOCKER_IMAGE   = "${DOCKERHUB_REPO}:${BUILD_NUMBER}"
        DOCKER_LATEST  = "${DOCKERHUB_REPO}:latest"

        // Docker Hub credentials ID (set in Jenkins Credentials)
        DOCKERHUB_CREDENTIALS = 'dockerhub-credentials-id'  // Add in Jenkins > Credentials
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from Git...'
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo 'Building the application with Maven...'
                sh 'mvn clean package -DskipTests'  // Skip tests here to speed up
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'  // Publish test results
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                sh """
                docker build -t ${DOCKER_IMAGE} .
                docker tag ${DOCKER_IMAGE} ${DOCKER_LATEST}
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo 'Pushing image to Docker Hub...'
                script {
                    docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS) {
                        sh """
                        docker push ${DOCKER_IMAGE}
                        docker push ${DOCKER_LATEST}
                        """
                    }
                }
            }
        }

        stage('Cleanup Local Images') {
            steps {
                echo 'Cleaning up local Docker images...'
                sh """
                docker rmi ${DOCKER_IMAGE} || true
                docker rmi ${DOCKER_LATEST} || true
                """
            }
        }

        // Optional: Deploy to EKS (uncomment if kubectl is configured)
        /*
        stage('Deploy to EKS') {
            steps {
                echo 'Deploying to EKS cluster...'
                sh """
                aws eks update-kubeconfig --region ap-south-1 --name my-eks-cluster
                kubectl set image deployment/your-app-deployment your-container=${DOCKER_IMAGE} -n your-namespace
                kubectl rollout status deployment/your-app-deployment -n your-namespace
                """
            }
        }
        */
    }

    post {
        success {
            echo 'Pipeline succeeded! Application built and pushed to Docker Hub.'
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            cleanWs()  // Clean workspace after build
        }
    }
}
