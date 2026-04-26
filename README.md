Цей проєкт містить Terraform-конфігурацію для розгортання базової інфраструктури на AWS (VPC, ECR, EKS) та Helm-чарт для розгортання Django-застосунку в кластері Kubernetes.

## Структура проєкту

- `main.tf` — Головний файл для підключення та конфігурації модулів Terraform.
- `backend.tf` — Налаштування S3-бекенду для зберігання стейтів та блокування.
- `outputs.tf` — Агреговані вихідні дані з усіх модулів.
- `modules/` — Каталог з перевикористовуваними модулями Terraform:
    - `s3-backend/` — Модуль для створення S3-бакета (стейт) та DynamoDB (блокування).
    - `vpc/` — Модуль для мережевої інфраструктури (VPC, підмережі, IGW, NAT GW), адаптований під EKS.
    - `ecr/` — Модуль для створення Elastic Container Registry.
    - `eks/` — Модуль для створення кластера Kubernetes (Control plane) та Node Group (Worker nodes).
    - `rds/` — Модуль для створення бази даних (Aurora Cluster або стандартна RDS instance).
- `charts/django-app/` — Каталог із Helm-чартом для нашого застосунку.

## Опис модулів

### s3-backend
Створює S3-бакет з увімкненим версіонуванням для безпечного зберігання `terraform.tfstate`. Також створює таблицю DynamoDB для керування блокуванням стейтів (State Locking), що запобігає одночасним змінам.
Модуль виводить назву бакета, URL бакета (`s3://...`) та ім'я таблиці DynamoDB.

### vpc
Створює віртуальну приватну хмару (VPC):
- 3 публічні підмережі з доступом до Internet Gateway.
- 3 приватні підмережі з доступом до інтернету через NAT Gateway.
- Налаштовує таблиці маршрутизації для обох типів підмереж.

### ecr
Створює репозиторій для Docker-образів з підтримкою автоматичного сканування на вразливості при кожному пуші (`scan_on_push = true`) та базовою політикою доступу.

### eks
Створює автоматично керований кластер AWS Elastic Kubernetes Service (EKS) версії 1.30. Також піднімає Node Group (на основі інстансів `t3.medium`) в приватних підмережах VPC для гарантування безпеки.

### jenkins
Встановлює Jenkins через Helm у namespace `jenkins` з типом сервісу `LoadBalancer`. Агент Jenkins використовує Kubernetes pod із контейнерами `kaniko` (збірка Docker-образів) та `git` (оновлення Helm chart).

### argo_cd
Встановлює Argo CD через Helm у namespace `argocd`. Автоматично реєструє `Application`, що стежить за гілкою `lesson-8-9` та шляхом `charts/django-app`, і синхронізує зміни у кластер (`prune: true`, `selfHeal: true`).

### rds
Універсальний модуль для створення реляційної бази даних на AWS. Підтримує два режими залежно від значення `use_aurora`:

- `use_aurora = false` (дефолт) → одна `aws_db_instance` (PostgreSQL, MySQL тощо)
- `use_aurora = true` → `aws_rds_cluster` + writer instance + reader replicas

В обох випадках автоматично створюються: `aws_db_subnet_group`, `aws_security_group`, parameter group з вказаними параметрами.

#### Приклад використання

```hcl
module "rds" {
  source = "./modules/rds"

  name       = "myapp-db"
  use_aurora = false          # true = Aurora Cluster

  # RDS-only (ігнорується при use_aurora=true)
  engine                     = "postgres"
  engine_version             = "17.2"
  parameter_group_family_rds = "postgres17"

  # Aurora-only (ігнорується при use_aurora=false)
  engine_cluster                = "aurora-postgresql"
  engine_version_cluster        = "15.3"
  parameter_group_family_aurora = "aurora-postgresql15"
  aurora_instance_count         = 2   # 1 writer + 1 reader

  # Спільні параметри
  instance_class          = "db.t3.medium"
  allocated_storage       = 20
  db_name                 = "myapp"
  username                = "postgres"
  password                = var.db_password
  vpc_id                  = module.vpc.vpc_id
  subnet_private_ids      = module.vpc.private_subnets
  subnet_public_ids       = module.vpc.public_subnets
  publicly_accessible     = false
  multi_az                = true
  backup_retention_period = 7

  parameters = {
    max_connections = "200"
    log_statement   = "all"
    work_mem        = "4096"
  }

  tags = {
    Environment = "production"
    Project     = "myapp"
  }
}
```

#### Змінні модуля `rds`

| Змінна | Тип | Дефолт | Опис |
|--------|-----|--------|------|
| `name` | string | — | Prefix для всіх ресурсів |
| `use_aurora` | bool | `false` | `true` = Aurora Cluster, `false` = RDS instance |
| `engine` | string | `"postgres"` | Engine для стандартного RDS |
| `engine_version` | string | `"14.7"` | Версія engine для стандартного RDS |
| `parameter_group_family_rds` | string | `"postgres15"` | Сімейство PG для стандартного RDS |
| `engine_cluster` | string | `"aurora-postgresql"` | Engine для Aurora |
| `engine_version_cluster` | string | `"15.3"` | Версія engine для Aurora |
| `parameter_group_family_aurora` | string | `"aurora-postgresql15"` | Сімейство PG для Aurora |
| `aurora_instance_count` | number | `2` | Кількість інстансів Aurora (1 writer + N-1 readers) |
| `instance_class` | string | `"db.t3.micro"` | Клас інстансу |
| `allocated_storage` | number | `20` | Розмір сховища у GB (тільки RDS) |
| `db_name` | string | — | Назва бази даних |
| `username` | string | — | Ім'я адміністратора |
| `password` | string | — | Пароль (sensitive) |
| `vpc_id` | string | — | ID VPC |
| `subnet_private_ids` | list(string) | — | ID приватних підмереж |
| `subnet_public_ids` | list(string) | — | ID публічних підмереж |
| `publicly_accessible` | bool | `false` | Публічний доступ |
| `multi_az` | bool | `false` | Multi-AZ (тільки RDS) |
| `backup_retention_period` | number | `7` | Днів зберігання резервних копій |
| `parameters` | map(string) | `{}` | Параметри для parameter group |
| `tags` | map(string) | `{}` | Теги ресурсів |

#### Як змінити тип БД / engine / клас інстансу

```hcl
# MySQL замість PostgreSQL
engine                     = "mysql"
engine_version             = "8.0"
parameter_group_family_rds = "mysql8.0"

# Aurora MySQL
use_aurora                    = true
engine_cluster                = "aurora-mysql"
engine_version_cluster        = "8.0.mysql_aurora.3.04.0"
parameter_group_family_aurora = "aurora-mysql8.0"

# Змінити клас інстансу (prod-ready)
instance_class = "db.r6g.large"
```

---

## CI/CD схема

```
[Git push] → [Jenkins pipeline]
                ├── Kaniko: build Docker image → push to ECR (tag v1.0.N)
                └── git: update charts/django-app/values.yaml → push to lesson-8-9
                                          ↓
                              [Argo CD detects change]
                                          ↓
                        [Helm sync django-app → EKS default namespace]
```

---

## Команди для роботи

### 1. Як застосувати Terraform

```bash
# Ініціалізація провайдерів та модулів
terraform init

# Попередній перегляд змін
terraform plan -var="jenkins_admin_password=YOUR_SECURE_PASSWORD"

# Застосування інфраструктури (VPC + ECR + EKS + Jenkins + Argo CD + RDS)
terraform apply -var="jenkins_admin_password=YOUR_SECURE_PASSWORD"

# Перевизначити пароль БД (за замовчуванням abcABC123):
terraform apply \
  -var="jenkins_admin_password=YOUR_SECURE_PASSWORD" \
  -var="db_password=YOUR_DB_PASSWORD"

# Підключення kubectl до кластера після apply
aws eks update-kubeconfig --region eu-north-1 --name eks-cluster-demo

# Отримати URL сервісів
terraform output jenkins_url
terraform output argocd_url
```

> ⚠️ Після застосування LoadBalancer-адреси з'являються через ~2-3 хвилини.
> Виконайте `kubectl get svc -n jenkins` та `kubectl get svc -n argocd` для перевірки `EXTERNAL-IP`.

---

### 2. Як перевірити Jenkins job

**Налаштування перед першим запуском:**

1. Отримайте пароль адміністратора:
   ```bash
   # Команда виводиться у terraform output:
   terraform output jenkins_admin_password_cmd
   # Виконайте команду, яку повернув output
   ```

2. Відкрийте Jenkins у браузері за `EXTERNAL-IP` на порту `8080`.

3. Увійдіть як `admin` з отриманим паролем.

4. Створіть Kubernetes secret з AWS credentials (для Kaniko → ECR push):
   ```bash
   kubectl create secret generic aws-credentials \
     -n jenkins \
     --from-file=credentials=$HOME/.aws/credentials \
     --from-file=config=$HOME/.aws/config
   ```

5. Додайте credentials (Manage Jenkins → Credentials → Global):
   - `github-credentials` — тип **Username with password** (GitHub username + Personal Access Token зі scope `repo`)
   - `aws-account-id` — тип **Secret text** (значення: ваш AWS Account ID, напр. `123456789012`)

6. Створіть pipeline job:
   - New Item → Pipeline
   - Definition: **Pipeline script from SCM**
   - SCM: Git, Repository URL: `https://github.com/novikor-goit/devops-ci-cd.git`
   - Branch: `*/lesson-8-9`
   - Script Path: `Jenkinsfile`

**Запуск та перевірка:**

```bash
# Після запуску job перевірте новий образ в ECR
aws ecr list-images --repository-name lesson-5-ecr --region eu-north-1

# Перевірте, що values.yaml оновився в Git
git pull origin lesson-8-9
grep "tag:" charts/django-app/values.yaml
```

---

### 3. Як побачити результат в Argo CD

1. Отримайте початковий пароль адміністратора:
   ```bash
   terraform output argocd_admin_password_cmd
   # Виконайте команду, яку повернув output
   ```
   Або напряму:
   ```bash
   kubectl get secret argocd-initial-admin-secret -n argocd \
     -o jsonpath='{.data.password}' | base64 -d
   ```

2. Відкрийте Argo CD UI за `EXTERNAL-IP` сервісу `argo-cd-argocd-server`:
   ```bash
   kubectl get svc argo-cd-argocd-server -n argocd
   ```

3. Увійдіть: логін `admin`, пароль з кроку 1.

4. На головній сторінці побачите Application **django-app**:
   - **Status**: `Synced` / `Healthy` — розгортання успішне.
   - **Revision**: поточний коміт гілки `lesson-8-9`.
   - Клікніть на застосунок → побачите поди, сервіси, HPA у кластері.

5. Після кожного запуску Jenkins pipeline Argo CD автоматично виявить зміну тегу в `values.yaml` і синхронізує новий образ:
   ```bash
   # Перевірити стан синхронізації через CLI
   kubectl get application django-app -n argocd

   # Переглянути поди застосунку після деплою
   kubectl get pods -n default
   ```

---

### Очищення ресурсів

> ⚠️ **УВАГА:** Обов'язково видаляйте ресурси після перевірки, щоб уникнути зайвих витрат.

```bash
# Видалення всієї інфраструктури
terraform destroy -var="jenkins_admin_password=YOUR_SECURE_PASSWORD"
```
