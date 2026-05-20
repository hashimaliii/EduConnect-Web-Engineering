@Library('jenkins-shared-library') _

pipeline {
    // Target the specific agent
    agent { label 'linux-agent' }

    // Inject the Slack webhook credential without exposing it in plaintext
    environment {
        SLACK_WEBHOOK = credentials('slack-webhook')
        AWS_CREDS = credentials('aws-credentials')
        AWS_DEFAULT_REGION = 'us-east-1'
        ECR_REPO = '694580673543.dkr.ecr.us-east-1.amazonaws.com/educonnect-app'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                dir('app') {
                    sh 'npm install'
                }
            }
        }

        stage('Test') {
            failFast true // If one parallel branch fails, the whole pipeline fails instantly
            parallel {
                stage('Unit Tests') {
                    environment {
                        // Tell jest-junit exactly where to put this specific report
                        JEST_JUNIT_OUTPUT_FILE = "unit-report.xml"
                    }
                    steps {
                        dir('app') {
                            sh 'npm run test:unit'
                        }
                    }
                    post {
                        always {
                            junit 'app/unit-report.xml'
                        }
                    }
                }
                
                stage('Integration Tests') {
                    environment {
                        JEST_JUNIT_OUTPUT_FILE = "integration-report.xml"
                    }
                    steps {
                        dir('app') {
                            sh 'npm run test:integration'
                        }
                    }
                    post {
                        always {
                            junit 'app/integration-report.xml'
                        }
                    }
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                dir('app') {
                    // Install AWS CLI dynamically to avoid rebuilding the EC2 agent
                    sh 'sudo apt-get update && sudo apt-get install -y awscli'
                    
                    // Inject AWS credentials as environment variables for the AWS CLI
                    withCredentials([usernamePassword(credentialsId: 'aws-credentials', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                        sh """
                            # 1. Authenticate Docker to AWS ECR
                            aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
                            
                            # 2. Build the Docker Image
                            docker build -t educonnect-app:${env.BUILD_NUMBER} .
                            
                            # 3. Tag the image with both the specific build number and 'latest'
                            docker tag educonnect-app:${env.BUILD_NUMBER} ${ECR_REPO}:${env.BUILD_NUMBER}
                            docker tag educonnect-app:${env.BUILD_NUMBER} ${ECR_REPO}:latest
                            
                            # 4. Push both tags to the secure AWS registry
                            docker push ${ECR_REPO}:${env.BUILD_NUMBER}
                            docker push ${ECR_REPO}:latest
                        """
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploy placeholder... We will build the Blue-Green deployment in Task 7'
            }
        }
    }

    // Post-build actions: Refactored Post-build actions using Shared Library
    post {
        always {
            archiveArtifacts artifacts: 'app/app.tar', allowEmptyArchive: true
        }
        success {
            notifySlack(
                status: 'SUCCESS',
                buildNumber: env.BUILD_NUMBER,
                buildUrl: env.BUILD_URL,
                branch: env.BRANCH_NAME,
                commit: env.GIT_COMMIT
            )
        }
        failure {
            notifySlack(
                status: 'FAILURE',
                buildNumber: env.BUILD_NUMBER,
                buildUrl: env.BUILD_URL,
                branch: env.BRANCH_NAME,
                commit: env.GIT_COMMIT
            )
        }
    }
}