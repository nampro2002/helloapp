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
                    // Nếu env.BRANCH_NAME bị null, lấy tên nhánh bằng git
                    if (!env.BRANCH_NAME) {
                        def gitBranch = sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
                        env.BRANCH_NAME = gitBranch
                    }
                    echo "Branch: ${env.BRANCH_NAME}"
                    echo "Change Target: ${env.CHANGE_TARGET ?: 'N/A'}"

                    // Checkout nếu là:
                    // - Push trực tiếp lên dev, feat/*, master
                    // - Hoặc PR nhắm tới master (CHANGE_TARGET = master)
                    if (env.BRANCH_NAME == 'dev' || env.BRANCH_NAME.startsWith('feat/') || 
                        env.BRANCH_NAME == 'master' || env.CHANGE_TARGET == 'master') {
                        echo "Performing checkout..."
                        checkout scm
                    } else {
                        echo "Skipping checkout for branch: ${env.BRANCH_NAME}"
                    }
                }
            }
        }

        stage('Build Docker Image') {
            when {
                anyOf {
                    // Push trực tiếp lên dev hoặc feat/*
                    branch 'dev'
                    branch pattern: "feat/.*", comparator: "REGEXP"
                    // Merge (approved) trên master
                    allOf {
                        branch 'master'
                        not { changeRequest() }
                    }
                    // PR nhắm tới master
                    allOf {
                        changeRequest()
                        expression { env.CHANGE_TARGET == 'master' }
                    }
                }
            }
            steps {
                sh '''
                    echo "Building Docker image..."
                    docker build -t ${DOCKER_IMAGE} .
                '''
            }
        }

        stage('Run SonarQube (SAST Scan)') {
            when {
                anyOf {
                    // PR nhắm tới master
                    allOf {
                        changeRequest()
                        expression { env.CHANGE_TARGET == 'master' }
                    }
                    // Merge (approved) trên master
                    allOf {
                        branch 'master'
                        not { changeRequest() }
                    }
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

        stage('Container Image Scan (Trivy)') {
            // Chỉ chạy khi merge (approved) trên master
            when {
                allOf {
                    branch 'master'
                    not { changeRequest() }
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

        stage('Deploy') {
            // Deploy chỉ khi merge (approved) trên master
            when {
                allOf {
                    branch 'master'
                    not { changeRequest() }
                }
            }
            steps {
                script {
                    echo "Deploying to environment..."
                    // Thêm các lệnh deploy của bạn (ví dụ: kubectl, docker-compose, v.v.)
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
