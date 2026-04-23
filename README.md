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

### jenkins
Встановлює Jenkins через Helm у namespace `jenkins` з типом сервісу `LoadBalancer`. Агент Jenkins використовує Kubernetes pod із контейнерами `kaniko` (збірка Docker-образів) та `git` (оновлення Helm chart).

### argo_cd
Встановлює Argo CD через Helm у namespace `argocd`. Автоматично реєструє `Application`, що стежить за гілкою `lesson-8-9` та шляхом `charts/django-app`, і синхронізує зміни у кластер (`prune: true`, `selfHeal: true`).

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

# Застосування інфраструктури (VPC + ECR + EKS + Jenkins + Argo CD)
terraform apply -var="jenkins_admin_password=YOUR_SECURE_PASSWORD"

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
