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

        stage('Deploy to K8s') {
            steps {
                // Retrieve BOTH the K8s config AND the AWS credentials
                withCredentials([
                    file(credentialsId: 'k8s-kubeconfig', variable: 'KUBECONFIG_FILE'),
                    usernamePassword(credentialsId: 'aws-credentials', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')
                ]) {
                    sh """
                        # 1. Install kubectl dynamically
                        curl -LO "https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl"
                        chmod +x kubectl
                        sudo mv kubectl /usr/local/bin/

                        # 2. Point kubectl to our specific cluster
                        export KUBECONFIG=\${KUBECONFIG_FILE}
                        
                        # 3. Create the Docker Registry Secret in Kubernetes so it can pull from ECR
                        # We extract just the registry URL from your ECR_REPO variable using cut
                        REGISTRY_URL=\$(echo \${ECR_REPO} | cut -d'/' -f1)
                        ECR_PASSWORD=\$(aws ecr get-login-password --region \${AWS_DEFAULT_REGION})
                        
                        kubectl create secret docker-registry ecr-secret \
                            --docker-server=https://\${REGISTRY_URL} \
                            --docker-username=AWS \
                            --docker-password=\${ECR_PASSWORD} \
                            --dry-run=client -o yaml | kubectl apply -f -
                        
                        # 4. Inject the specific Docker image URL into our YAML file
                        sed -i "s|IMAGE_URL_PLACEHOLDER|\${ECR_REPO}:\${env.BUILD_NUMBER}|g" k8s/deployment.yaml

                        # 5. Deploy the application to Kubernetes
                        kubectl apply -f k8s/
                        
                        # 6. Wait for the pods to boot
                        kubectl rollout status deployment/educonnect-app-deployment
                    """
                }
            }
        }
    }

    // Refactored Post-build actions using Shared Library
    post {
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
}