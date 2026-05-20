pipeline {
    // Target the specific agent
    agent { label 'linux-agent' }

    // Inject the Slack webhook credential without exposing it in plaintext
    environment {
        SLACK_WEBHOOK = credentials('slack-webhook')
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

        stage('Package') {
            steps {
                echo 'Packaging application...'
                dir('app') {
                    sh 'tar -cvf app.tar *'
                }
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploy placeholder... We will build the Blue-Green deployment in Task 7'
            }
        }
    }

    // Post-build actions
    post {
        always {
            archiveArtifacts artifacts: 'app/app.tar', allowEmptyArchive: true
        }
        success {
            sh """
                curl -X POST -H 'Content-type: application/json' \
                --data '{"text":"✅ SUCCESS: Pipeline completed. See build: ${env.BUILD_URL}"}' \
                ${SLACK_WEBHOOK}
            """
        }
        failure {
            sh """
                curl -X POST -H 'Content-type: application/json' \
                --data '{"text":"❌ FAILURE: Pipeline failed. See build logs: ${env.BUILD_URL}"}' \
                ${SLACK_WEBHOOK}
            """
        }
    }
}