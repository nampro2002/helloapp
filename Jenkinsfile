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
                        // Lấy tên branch và target branch của PR (nếu có)
                        def branchName = env.BRANCH_NAME ?: ''
                        def changeTarget = env.CHANGE_TARGET ?: ''
                        echo "Branch: ${branchName}, Change Target: ${changeTarget}"
    
                        // Nếu đang push trực tiếp lên dev, feat/*, master hoặc là PR nhắm tới master thì checkout code
                        if (branchName == 'dev' || branchName.startsWith('feat/') || branchName == 'master' || changeTarget == 'master') {
                            echo "Checking out code..."
                            checkout scm
                        } else {
                            echo "Skipping checkout for branch: ${branchName}"
                        }
                    }
                }
            }
            stage('Maven Build') {
                steps {
                    script {
                        // Chạy lệnh build Maven để tạo các file cần thiết cho SonarQube (ví dụ: target/classes)
                        echo "Running Maven build..."
                        sh 'mvn clean install'
                    }
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
                        // Merge vào master (approved build)
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
            
            stage('Build Docker Image') {
                when {
                    anyOf {
                        // Push trực tiếp lên dev hoặc feat/*
                        branch 'dev'
                        branch pattern: "feat/.*", comparator: "REGEXP"
                        // Merge vào master (approved build)
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
            
            stage('Container Image Scan (Trivy)') {
                // Chỉ chạy khi merge (approved build) trên branch master
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
            stage('Container Validation Test') {
                when {
                    allOf {
                        branch 'master'
                        not { changeRequest() }
                    }
                }
                steps {
                    script {
                        echo "Starting container..."
                        def containerId = sh(script: 'docker run -d --rm -p 8081:8081 ${DOCKER_IMAGE}', returnStdout: true).trim()
            
                        echo "Waiting for container to be ready..."
                        sleep 10  // Chờ 10 giây trước khi kiểm tra
            
                        echo "Checking container health..."
                        def max_retries = 5
                        def count = 0
                        def healthCheck = 1
            
                        while (count < max_retries) {
                            healthCheck = sh(script: 'curl -sf http://localhost:8081', returnStatus: true)
                            if (healthCheck == 0) {
                                break
                            }
                            echo "Retrying health check... Attempt ${count + 1}/${max_retries}"
                            sleep 5
                            count++
                        }
            
                        if (healthCheck != 0) {
                            echo "Container failed health check! Stopping container..."
                            sh "docker stop ${containerId}"
                            error "Health check failed!"
                        } else {
                            echo "Container is healthy!"
                            sh "docker stop ${containerId}"
                        }
                    }
                }
            }


            stage('Push to DockerHub') {
                when {
                    allOf {
                        branch 'master'
                        not { changeRequest() }
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
                        branch 'master'
                        not { changeRequest() }
                    }
                }
                steps {
                    script {
                        echo "Deploying to environment..."
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
