pipeline {
    agent {
        kubernetes {
            label 'docker-build'
            yaml """
apiVersion: v1
kind: Pod
spec:
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
"""
        }
    }
    environment {
        AWS_CREDENTIALS_ID = 'aws-ecr'
        AWS_ACCOUNT_ID = '182399711446'
        ECR_REPOSITORY = '182399711446.dkr.ecr.eu-north-1.amazonaws.com/word-cloud-generator'
        IMAGE_TAG = "latest"
        SONARQUBE_SCANNER = 'SonarQube Scanner'
        KUBECONFIG_CREDENTIALS_ID = '1d78077e-a7f2-4810-83bf-473197cee94c'
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
                    sh 'dockerd-entrypoint.sh &>/dev/null &'
                    sh 'sleep 20'
                    sh "docker --version"
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
                            // Using aws ecr get-login-password 
                            sh """
                                aws ecr get-login-password --region ${AWS_REGION} | docker login -u AWS --password-stdin ${ECR_REPOSITORY}
                            """
                        }
                        sh "docker push ${ECR_REPOSITORY}:${IMAGE_TAG}"
                    }
                }
            }
        }

        stage('Deploy to Kubernetes with Helm') {
            agent {
                kubernetes { label 'master' } 
            }
            steps {
                script {
                     withCredentials([file(credentialsId: "${KUBECONFIG_CREDENTIALS_ID}", variable: 'KUBECONFIG')]) {
                        sh "helm upgrade --install word-cloud-generator ./helm/word-cloud-generator --set image.repository=${ECR_REPOSITORY} --set image.tag=${IMAGE_TAG} --kubeconfig $KUBECONFIG"
                    }
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