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
        GIT_REPO = 'https://github.com/wickett/word-cloud-generator.git' 
        GITHUB_REPO = 'https://github.com/Proffesor94/rsschool-devops-course-tasks'
        GITHUB_BRANCH = 'task_6'
        SONAR_HOST_URL = 'https://sonarcloud.io'
        SONAR_PROJECT_KEY = 'task-6-word-cloud-generator'
        SONAR_ORGANIZATION = 'proffesor94'
        SONAR_TOKEN = credentials('sonar-token')
        SONAR_SCANNER_VERSION = '6.2.1.4610'
        SONAR_SCANNER_HOME = "$HOME/.sonar/sonar-scanner-${SONAR_SCANNER_VERSION}-linux-x64"
    }
    stages {
        stage('Checkout Dockerfile') {
            steps {
                git url: "${GITHUB_REPO}", branch: "${GITHUB_BRANCH}"
            }
         }       
        stage('Checkout Application Code') { 
            steps {
               git url: "${GIT_REPO}", branch: 'main'
            }
        }
        stage('Prepare Docker') {
            steps {
                container('docker') {
                    sh 'dockerd-entrypoint.sh &>/dev/null &' // Start Docker daemon
                    sh 'sleep 20'                            // Wait for Docker to initialize
                    sh 'apk update && apk add --no-cache aws-cli kubectl'  // Install necessary tools
                    sh 'aws --version'                       // Verify AWS CLI installation
                    sh 'docker --version'                    // Verify Docker installation
                    sh 'kubectl version --client'            // Verify kubectl installation
                }
            }
        }
        stage('Unit Tests') {  
            steps {
                git url: "${GITHUB_REPO}", branch: "${GITHUB_BRANCH}" // Checkout here as well
                container('docker') {
                    sh "docker build -t word-cloud-generator-builder -f Dockerfile --target builder ."  
                    sh "docker run --rm word-cloud-generator-builder go test -v ./..." 
                }
            }
        }
        stage('SonarQube Analysis') {
            steps {
                container('docker') {
                    script {
                    // Install OpenJDK 17 if necessary (already in the docker container)
                    sh """
                      apk add --no-cache -q openjdk17
                      export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
                      export PATH=\$JAVA_HOME/bin:\$PATH
                      java -version
                    """

                    // Use SonarQubeScanner tool configured in Jenkins
                    def scannerHome = tool 'SonarQubeScanner'

                        // Run SonarQube analysis with appropriate parameters
                        withSonarQubeEnv('SonarQube') {
                          sh """
                            ${scannerHome}/bin/sonar-scanner \
                              -Dsonar.projectKey=task-6-word-cloud-generator \
                              -Dsonar.sources=. \
                              -Dsonar.host.url=https://sonarcloud.io \
                              -Dsonar.login=${SONAR_TOKEN} \
                              -Dsonar.organization=${SONAR_ORGANIZATION}
                          """
                        }
                    }
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
            when { expression { params.PUSH_TO_ECR == true } }
            steps {
                script {
                    if (currentBuild.result != 'FAILURE') {  //Capture success (or unstable)
                        env.PUSH_SUCCESSFUL = true
                    } else {
                        env.PUSH_SUCCESSFUL = false // Explicitly set to false on failure
                        }
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
        stage('Create ECR Secret') {
            steps {
                container('docker') {
                    withCredentials([aws(credentialsId: "${AWS_CREDENTIALS_ID}")]) {
                        sh """
                        aws ecr get-login-password --region \${AWS_REGION} | docker login --username AWS --password-stdin \${ECR_REPOSITORY}

                        kubectl create secret generic ecr-secret --namespace=jenkins --from-file=.dockerconfigjson=\$HOME/.docker/config.json --dry-run=client -o json | kubectl apply -f -
                        """
                    }
                }
            }
        }
        stage('Deploy to Kubernetes with Helm') {
            when { expression { params.PUSH_TO_ECR == true } }
            steps {
                container('helm') {
                    sh """
                    helm upgrade --install word-cloud-generator ./helm/word-cloud-generator \\
                        --set image.repository=${ECR_REPOSITORY} \\
                        --set image.tag=${IMAGE_TAG} \\
                        -f ./helm/word-cloud-generator/values.yaml \\
                        --namespace jenkins
                    """
                }
            }
        }
    }    
    post {
        always {
            cleanWs()
            mail to: 'serfer94@gmail.com',
            subject: "Jenkins Build: ${currentBuild.result}",
            body: "Job: ${env.JOB_NAME} \n Build Number: ${env.BUILD_NUMBER}"
        }
    }
}