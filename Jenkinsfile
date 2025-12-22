pipeline {
    agent any

    environment {
        // Docker image details
        DOCKERHUB_REPO = 'sdfa777/capstone-health-project2'
        DOCKER_IMAGE   = "${DOCKERHUB_REPO}:${BUILD_NUMBER}"
        DOCKER_LATEST  = "${DOCKERHUB_REPO}:latest"

        // Credentials & Cluster Info
        DOCKERHUB_CREDENTIALS = 'dockerhub-credentials-id'
        AWS_REGION            = 'ap-south-1'
        EKS_CLUSTER_NAME      = 'capstone-project'
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
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS}", 
                                                      usernameVariable: 'DOCKER_USER', 
                                                      passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_IMAGE}
                        docker push ${DOCKER_LATEST}
                        docker logout
                        '''
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    // Update kubeconfig to point to your EKS cluster
                    sh "aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}"
                    
                    // Update the deployment with the new image
                    // Replace 'capstone-project' with your actual Deployment name if different
                    sh "kubectl set image deployment/capstone-project capstone-app=${DOCKER_IMAGE} --record"
                    
                    // Check rollout status
                    sh "kubectl rollout status deployment/capstone-project"
                    
                    echo "Deployment to EKS successful!"
                }
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
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            cleanWs()
        }
    }
}
