output "web_sg_id" {
  value = aws_security_group.web_sg.id
}

output "db_sg_id" {
  value = aws_security_group.db_sg.id
}

output "jenkins_controller_sg_id" {
  value = aws_security_group.jenkins_controller_sg.id
}

output "jenkins_agent_sg_id" {
  value = aws_security_group.jenkins_agent_sg.id
}