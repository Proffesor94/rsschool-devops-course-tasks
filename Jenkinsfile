pipeline {
    agent {
        kubernetes {
            label 'docker-build'
            yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
  - name: jenkins-agent
    image: jenkins/inbound-agent:latest
    command:
    - cat
    tty: true
    securityContext:
      privileged: true
  - name: docker
    image: docker:dind
    securityContext:
      privileged: true
  - name: helm
    image: alpine/helm:3.11.1  # Helm container
    command: ['cat']
    tty: true
"""
        }
    }
    environment {
        AWS_CREDENTIALS_ID = 'aws-ecr'
        AWS_ACCOUNT_ID = '182399711446'
        ECR_REPOSITORY = '182399711446.dkr.ecr.eu-north-1.amazonaws.com/word-cloud-generator'
        IMAGE_TAG = "latest"
        SONARQUBE_SCANNER = 'SonarQube Scanner'
        AWS_REGION = 'eu-north-1'
        DOCKERFILE_REPO = 'https://github.com/Proffesor94/rsschool-devops-course-tasks'
        DOCKERFILE_BRANCH = 'task_6'
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: "${DOCKERFILE_BRANCH}", url: "${DOCKERFILE_REPO}"
            }
        }
        stage('Prepare Docker') {
            steps {
                container('docker') {
                    sh 'dockerd-entrypoint.sh &>/dev/null &'   // Start Docker daemon
                    sh 'sleep 20'                            // Wait for Docker to initialize
                    sh 'apk add --no-cache aws-cli helm'         // Install AWS CLI and Helm
                    sh 'aws --version'                       // Verify AWS CLI installation
                    sh 'docker --version'                    // Verify Docker installation
                    sh 'helm version --short'               // Verify Helm installation
                }
            }
        }
        stage('Application Build') {
            steps {
                container('docker') {
                    sh "docker build -t ${ECR_REPOSITORY}:${IMAGE_TAG} ."
                }
            }
        }
        stage('Push Docker Image to ECR') {
            steps {
                script {
                    container('docker') {
                        withCredentials([aws(credentialsId: "${AWS_CREDENTIALS_ID}")]) {
                            // Log in to ECR
                            sh """
                            aws ecr get-login-password --region ${AWS_REGION} | docker login -u AWS --password-stdin ${ECR_REPOSITORY}
                            """
                        }
                        // Push Docker image to ECR
                        sh "docker push ${ECR_REPOSITORY}:${IMAGE_TAG}"
                    }
                }
            }
        }
        stage('Deploy to Kubernetes with Helm') {
            steps {
                container('helm') {
                    sh """
                    helm upgrade --install word-cloud-generator ./helm/word-cloud-generator \
                        --set image.repository=${ECR_REPOSITORY} \
                        --set image.tag=${IMAGE_TAG}
                    """
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
