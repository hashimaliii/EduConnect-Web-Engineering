pipeline {
    agent { label 'linux-agent' }

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        ECR_REPO = '694580673543.dkr.ecr.us-east-1.amazonaws.com/educonnect-app'
        ALB_ARN = 'REPLACE_WITH_YOUR_ALB_ARN'
        TG_BLUE_ARN = 'REPLACE_WITH_YOUR_TG_BLUE_ARN'
        TG_GREEN_ARN = 'REPLACE_WITH_YOUR_TG_GREEN_ARN'
        ASG_BLUE_NAME = 'asg-blue'
        ASG_GREEN_NAME = 'asg-green'
        S3_LOG_BUCKET = 'REPLACE_WITH_YOUR_S3_BUCKET_NAME'
        SHORT_COMMIT = "${env.GIT_COMMIT[0..6]}"
    }

    stages {
        stage('Checkout & Setup') {
            steps {
                checkout scm
                // Install Trivy dynamically for Task 5
                sh 'sudo apt-get install wget apt-transport-https gnupg lsb-release -y && wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add - && echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list && sudo apt-get update && sudo apt-get install trivy -y'
            }
        }

        stage('Container Build') {
            steps {
                dir('app') {
                    // Task 5: Build and tag with both short commit and branch name
                    sh """
                        docker build -t ${ECR_REPO}:${SHORT_COMMIT} -t ${ECR_REPO}:${env.BRANCH_NAME} .
                    """
                }
            }
        }

        stage('Security Scan') {
            steps {
                dir('app') {
                    // Task 5: Fail on HIGH/CRITICAL with available fixes, output to report
                    sh """
                        trivy image --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed --format table --output trivy-report.txt ${ECR_REPO}:${SHORT_COMMIT}
                    """
                }
            }
            post {
                always {
                    // Task 5: Always archive the scan report
                    archiveArtifacts artifacts: 'app/trivy-report.txt', allowEmptyArchive: true
                }
            }
        }

        stage('Push to ECR') {
            steps {
                // Relies on the IAM role attached to the EC2 instance (No long-lived credentials block needed)
                sh """
                    aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
                    docker push ${ECR_REPO}:${SHORT_COMMIT}
                    docker push ${ECR_REPO}:${env.BRANCH_NAME}
                """
            }
        }

        stage('Deploy-Production') {
            when { branch 'main' }
            steps {
                sh '''#!/bin/bash
                    set -e
                    
                    # 1. Determine Live and Idle Environments
                    LIVE_LISTENER=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --query "Listeners[?Port==\`80\`].ListenerArn" --output text)
                    TEST_LISTENER=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --query "Listeners[?Port==\`8080\`].ListenerArn" --output text)
                    LIVE_TG=$(aws elbv2 describe-listeners --listener-arns $LIVE_LISTENER --query "Listeners[0].DefaultActions[0].TargetGroupArn" --output text)
                    
                    if [ "$LIVE_TG" == "$TG_BLUE_ARN" ]; then
                        LIVE_COLOR="blue"
                        IDLE_COLOR="green"
                        IDLE_TG=$TG_GREEN_ARN
                        IDLE_ASG=$ASG_GREEN_NAME
                    else
                        LIVE_COLOR="green"
                        IDLE_COLOR="blue"
                        IDLE_TG=$TG_BLUE_ARN
                        IDLE_ASG=$ASG_BLUE_NAME
                    fi
                    
                    echo "Current LIVE is $LIVE_COLOR. Deploying to IDLE $IDLE_COLOR."
                    
                    # 2. Update Application via SSM Parameter (Read by ASG User Data)
                    aws ssm put-parameter --name "/educonnect/deploy/target_tag" --value "$SHORT_COMMIT" --type "String" --overwrite
                    
                    # 3. Trigger Instance Refresh on Idle ASG
                    aws autoscaling start-instance-refresh --auto-scaling-group-name $IDLE_ASG
                    
                    # Wait for refresh to complete (Polling)
                    STATUS="InProgress"
                    while [ "$STATUS" != "Successful" ]; do
                        sleep 15
                        STATUS=$(aws autoscaling describe-instance-refreshes --auto-scaling-group-name $IDLE_ASG --query "InstanceRefreshes[0].Status" --output text)
                        if [ "$STATUS" == "Failed" ] || [ "$STATUS" == "Cancelled" ]; then
                            echo "Instance refresh failed!"
                            exit 1
                        fi
                        echo "Refresh status: $STATUS"
                    done
                    
                    # 4. Smoke Test on Port 8080
                    ALB_DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --query "LoadBalancers[0].DNSName" --output text)
                    echo "Running smoke test against http://$ALB_DNS:8080/health"
                    
                    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$ALB_DNS:8080/health)
                    if [ "$HTTP_STATUS" != "200" ]; then
                        echo "Smoke test failed with status $HTTP_STATUS. Aborting switch."
                        LOG_RESULT="failed"
                    else
                        echo "Smoke test passed. Flipping traffic..."
                        # 5. Flip the Listeners
                        aws elbv2 modify-listener --listener-arn $LIVE_LISTENER --default-actions Type=forward,TargetGroupArn=$IDLE_TG
                        aws elbv2 modify-listener --listener-arn $TEST_LISTENER --default-actions Type=forward,TargetGroupArn=$LIVE_TG
                        LOG_RESULT="success"
                    fi
                    
                    # 6. S3 Deployment Logging
                    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
                    LOG_ENTRY="{\\"timestamp\\":\\"$TIMESTAMP\\", \\"commit\\":\\"$SHORT_COMMIT\\", \\"tag\\":\\"$BRANCH_NAME\\", \\"previous_color\\":\\"$LIVE_COLOR\\", \\"new_color\\":\\"$IDLE_COLOR\\", \\"result\\":\\"$LOG_RESULT\\"}"
                    echo $LOG_ENTRY > deployment_log.json
                    aws s3 cp s3://$S3_LOG_BUCKET/master_log.json existing_log.json || touch existing_log.json
                    cat deployment_log.json >> existing_log.json
                    aws s3 cp existing_log.json s3://$S3_LOG_BUCKET/master_log.json
                    
                    if [ "$LOG_RESULT" == "failed" ]; then exit 1; fi
                '''
            }
        }
    }
}