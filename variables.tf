variable "jenkins_admin_password" {
  description = "Initial admin password for Jenkins"
  type        = string
  sensitive   = true
  default     = "abcABC123"
}
