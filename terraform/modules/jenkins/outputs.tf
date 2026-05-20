output "controller_public_ip" {
  value = aws_instance.jenkins_controller.public_ip
}

output "agent_private_ip" {
  value = aws_instance.jenkins_agent.private_ip
}