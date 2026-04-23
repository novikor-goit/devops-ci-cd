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

## Команди для роботи

### Розгортання інфраструктури (Terraform)

1. **Ініціалізація та застосування інфраструктури:**
   ```bash
   terraform init
   terraform apply
   ```

2. **Підключення локального kubectl до кластера EKS:**
   ```bash
   aws eks update-kubeconfig --region eu-north-1 --name eks-cluster-demo
   ```

### Робота із застосунком (Docker & Helm)

1. **Авторизація та завантаження образу в ECR (з минулих лекцій):**
   ```bash
   aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin <ВАШ_AWS_ACCOUNT_ID>.dkr.ecr.eu-north-1.amazonaws.com
   docker build -t lesson-5-ecr .
   docker tag lesson-5-ecr:latest <ВАШ_AWS_ACCOUNT_ID>.dkr.ecr.eu-north-1.amazonaws.com/lesson-5-ecr:latest
   docker push <ВАШ_AWS_ACCOUNT_ID>.dkr.ecr.eu-north-1.amazonaws.com/lesson-5-ecr:latest
   ```

2. **Розгортання Django-застосунку через Helm:**
   ```bash
   helm install django-app ./charts/django-app
   ```

3. **Перевірка стану масштабування (HPA), подів та сервісів:**
   ```bash
   kubectl get pods,svc,hpa
   ```
   *Зверніть увагу на поле `EXTERNAL-IP` у виводі сервісу `django-app` — саме за цим посиланням буде доступний застосунок.*

### Очищення ресурсів

1. **Видалення застосунку з кластера:**
   ```bash
   helm uninstall django-app
   ```

2. **Видалення інфраструктури AWS:**
   ```bash
   terraform destroy
   ```
