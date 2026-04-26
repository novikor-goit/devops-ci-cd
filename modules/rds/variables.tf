variable "name" {
  description = "Назва інстансу або кластера (prefix для всіх ресурсів)"
  type        = string
}

variable "use_aurora" {
  description = "true = Aurora Cluster; false = звичайна RDS instance"
  type        = bool
  default     = false
}

variable "engine" {
  description = "Engine для стандартного RDS (наприклад postgres, mysql)"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Версія engine для стандартного RDS"
  type        = string
  default     = "14.7"
}

variable "engine_cluster" {
  description = "Engine для Aurora кластера (наприклад aurora-postgresql, aurora-mysql)"
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version_cluster" {
  description = "Версія engine для Aurora кластера"
  type        = string
  default     = "15.3"
}

variable "aurora_instance_count" {
  description = "Кількість інстансів Aurora (1 writer + N-1 readers)"
  type        = number
  default     = 2
}

variable "instance_class" {
  description = "Клас інстансу БД (наприклад db.t3.micro, db.t3.medium)"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Розмір сховища у GB (тільки для стандартного RDS)"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Назва бази даних"
  type        = string
}

variable "username" {
  description = "Ім'я адміністратора БД"
  type        = string
}

variable "password" {
  description = "Пароль адміністратора БД"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "ID VPC, де розміщується БД"
  type        = string
}

variable "subnet_private_ids" {
  description = "Список ID приватних підмереж"
  type        = list(string)
}

variable "subnet_public_ids" {
  description = "Список ID публічних підмереж"
  type        = list(string)
}

variable "publicly_accessible" {
  description = "Чи доступна БД з інтернету"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Увімкнути Multi-AZ для стандартного RDS"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Кількість днів зберігання автоматичних резервних копій"
  type        = number
  default     = 7
}

variable "parameters" {
  description = "Додаткові параметри для parameter group (map назва => значення)"
  type        = map(string)
  default     = {}
}

variable "parameter_group_family_aurora" {
  description = "Сімейство parameter group для Aurora (наприклад aurora-postgresql15)"
  type        = string
  default     = "aurora-postgresql15"
}

variable "parameter_group_family_rds" {
  description = "Сімейство parameter group для стандартного RDS (наприклад postgres15)"
  type        = string
  default     = "postgres15"
}

variable "tags" {
  description = "Теги, що застосовуються до всіх ресурсів модуля"
  type        = map(string)
  default     = {}
}
