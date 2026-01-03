pipeline {
    agent any

    environment {
        DOCKERHUB_REPO = 'sdfa777/health-project-2'
        DOCKER_IMAGE   = "${DOCKERHUB_REPO}:${BUILD_NUMBER}"
        DOCKER_LATEST  = "${DOCKERHUB_REPO}:latest"

        DOCKERHUB_CREDENTIALS = 'dockerhub-credentials-id'
        AWS_REGION            = 'ap-south-1'
        EKS_CLUSTER_NAME      = 'kubernetes'
        K8S_NAMESPACE         = 'default'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

stage('Build Docker Image') {
    steps {
        sh """
        docker build -t ${DOCKER_IMAGE} .
        docker tag ${DOCKER_IMAGE} ${DOCKER_LATEST}
        docker images | grep health
        """
    }
}

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: DOCKERHUB_CREDENTIALS,
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                    echo "\$DOCKER_PASS" | docker login -u "\$DOCKER_USER" --password-stdin
                    docker push ${DOCKER_IMAGE}
                    docker push ${DOCKER_LATEST}
                    docker logout
                    """
                }
            }
        }
        
stage('Deploy to jenkins') {
    steps {
        // Use the actual ID you created in Jenkins (e.g., 'ansible-key')
        sshagent(credentials: ['key']) { 
            sh """
            # Use 'ansible' here instead of 'ubuntu' if that is your target user
            ssh -o StrictHostKeyChecking=no ansible@${env.jenkins} << 'EOF'
              docker pull ${DOCKER_IMAGE}

              docker stop health-app || true
              docker rm health-app || true

              docker run -d \\
                --name health-app \\
                -p 8081:8080 \\
                ${DOCKER_IMAGE}
            EOF
            """
        }
    }
}


       stage('Deploy to EKS') {
           steps {
               sh """
               aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}

               kubectl set image deployment/health-project-2 \
                 health-app=${DOCKER_IMAGE} \
                 -n default

               kubectl rollout status deployment/health-project-2 -n default
               """
    }
}


        stage('Cleanup Local Images') {
            steps {
                sh """
                docker rmi ${DOCKER_IMAGE} || true
                docker rmi ${DOCKER_LATEST} || true
                """
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline succeeded!'
        }
        failure {
            echo '❌ Pipeline failed!'
        }
        always {
            cleanWs()
        }
    }
}
