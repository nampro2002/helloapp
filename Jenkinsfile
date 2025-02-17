pipeline {
    agent any

    environment {
        SONARQUBE_SERVER_URL = credentials('sonarqube-server-url')
        SONAR_PROJECT_KEY = 'helloapp'
        DOCKER_IMAGE = 'helloapp:latest'
    }

    stages { 
        stage('SCM Checkout') {
            steps {
                script {
                    def branchName = env.BRANCH_NAME
                    echo "Branch: ${branchName}"

                    // Cấu hình checkout cho các nhánh dev và feat/*
                    if (branchName == 'dev' || branchName.startsWith('feat/')) {
                        echo "Checkout for branch: ${branchName}"
                        checkout scm
                    } else {
                        echo "Skipping checkout for non-Dev or non-Feat branch"
                    }
                }
            }
        }

        stage('Run SonarQube (SAST Scan)') {
            when {
                anyOf {
                    branch 'dev'
                    branch pattern: "feat/.*", comparator: "REGEXP"
                    changeRequest() // Trigger PR scan
                }
            }
            environment {
                scannerHome = tool 'scanner-test-v1'
            }
            steps {
                withSonarQubeEnv(credentialsId: 'sonarqube', installationName: 'scanner-test-v1') {
                    sh '''
                        if [ ! -d "target/classes" ]; then
                            echo "ERROR: target/classes does not exist. Did you forget to build the project?"
                            exit 1
                        fi

                        ${scannerHome}/bin/sonar-scanner \
                        -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                        -Dsonar.projectName="Laptop Store Backend" \
                        -Dsonar.projectVersion=1.0 \
                        -Dsonar.sources=src \
                        -Dsonar.language=java \
                        -Dsonar.java.binaries=target/classes \
                        -Dsonar.host.url=${SONARQUBE_SERVER_URL} \
                        -Dsonar.token=$SONAR_TOKEN
                    '''
                }
            }
        }

        stage('Dockerfile Scan (Hadolint)') {
            when {
                anyOf {
                    branch 'dev'
                    branch pattern: "feat/.*", comparator: "REGEXP"
                    changeRequest() // Trigger PR scan
                }
            }
            steps {
                script {
                    def hadolintResult = sh(script: 'hadolint Dockerfile', returnStatus: true)
                    if (hadolintResult != 0) {
                        error "Hadolint found issues in Dockerfile!"
                    }
                }
            }
        }

        stage('Build Docker Image') {
            when {
                anyOf {
                    branch 'dev'
                    branch pattern: "feat/.*", comparator: "REGEXP"
                    changeRequest() // Trigger PR build
                }
            }
            steps {
                sh '''
                    echo "Building Docker image..."
                    docker build -t ${DOCKER_IMAGE} .
                '''
            }
        }

        stage('Container Image Scan (Trivy)') {
            when {
                anyOf {
                    branch 'dev'
                    branch pattern: "feat/.*", comparator: "REGEXP"
                    changeRequest() // Trigger PR scan
                }
            }
            steps {
                script {
                    def trivyResult = sh(script: 'trivy image --exit-code 1 --severity HIGH,CRITICAL ${DOCKER_IMAGE}', returnStatus: true)
                    if (trivyResult != 0) {
                        echo "Trivy found high/critical vulnerabilities in Docker image!"
                    }
                }
            }
        }

        stage('Push to DockerHub') {
            when {
                allOf {
                    branch 'dev'
                    not {
                        changeRequest() // Do not push during PR phase
                    }
                }
            }
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh '''
                            echo "Logging in to DockerHub..."
                            docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
                        '''
                        sh '''
                            echo "Pushing Docker image to DockerHub..."
                            docker tag ${DOCKER_IMAGE} cannam2002/helloapp:latest
                            docker push cannam2002/helloapp:latest
                        '''
                    }
                }
            }
        }

        stage('Deploy') {
            when {
                allOf {
                    branch 'dev'
                    not {
                        changeRequest() // Do not deploy during PR phase
                    }
                }
            }
            steps {
                script {
                    echo "Deploying to environment..."
                    // Add your deployment commands here (e.g., kubectl or docker-compose)
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution completed.'
        }
        success {
            echo 'Pipeline executed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}
