variable "cluster_name" {
  description = "Назва EKS-кластера"
  type        = string
}

variable "cluster_version" {
  description = "Версія Kubernetes для EKS-кластера"
  type        = string
}

variable "cluster_subnet_ids" {
  description = "Список ID сабнетів для control plane EKS"
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "Список ID приватних сабнетів для worker nodes"
  type        = list(string)
}

variable "node_group_name" {
  description = "Назва node group"
  type        = string
}

variable "node_instance_types" {
  description = "Типи інстансів для worker nodes"
  type        = list(string)
}

variable "desired_size" {
  description = "Бажана кількість worker nodes"
  type        = number
}

variable "min_size" {
  description = "Мінімальна кількість worker nodes"
  type        = number
}

variable "max_size" {
  description = "Максимальна кількість worker nodes"
  type        = number
}