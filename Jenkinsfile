pipeline {
    agent any

    environment {
        // Docker image details
        DOCKERHUB_REPO = 'sdfa777/health-star-agile-project2'
        DOCKER_IMAGE   = "${DOCKERHUB_REPO}:${BUILD_NUMBER}"
        DOCKER_LATEST  = "${DOCKERHUB_REPO}:latest"

        // Credentials & Cluster Info
        DOCKERHUB_CREDENTIALS = 'dockerhub-credentials-id'
        AWS_REGION            = 'ap-south-1'
        EKS_CLUSTER_NAME      = 'medicure-eks'
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
            // 1. Update Kubeconfig (This uses the EC2 IAM Role we just authorized)
               sh "aws eks update-kubeconfig --region ap-south-1 --name medicure-eks"
            
            // 2. Trigger the Rolling Update
            // This replaces the old image with the one we just built/pushed
               sh "kubectl set image deployment/health-star-agile health-app=${DOCKER_IMAGE}"
            
            // 3. Monitor the Rollout
            // Jenkins will wait here until the new pods are Ready. 
            // If the pods crash, Jenkins will fail the build here!
               sh "kubectl rollout status deployment/health-star-agile"
            
               echo "🚀 Deployment to EKS capstone-project successful!"
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
