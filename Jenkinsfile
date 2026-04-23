pipeline {
    agent {
        kubernetes {
            defaultContainer 'kaniko'
            yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:debug
      command:
        - /busybox/cat
      tty: true
      volumeMounts:
        - name: aws-credentials
          mountPath: /root/.aws
    - name: git
      image: alpine/git:latest
      command:
        - cat
      tty: true
  volumes:
    - name: aws-credentials
      secret:
        secretName: aws-credentials
"""
        }
    }

    environment {
        AWS_REGION  = "eu-north-1"
        AWS_ACCOUNT = credentials('aws-account-id')
        ECR_REPO    = "lesson-5-ecr"
        IMAGE_REPO  = "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"
        IMAGE_TAG   = "${BUILD_NUMBER}"
        GIT_REPO    = "https://github.com/novikor-goit/devops-ci-cd.git"
        GIT_BRANCH  = "lesson-8-9"
        VALUES_FILE = "charts/django-app/values.yaml"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: "${GIT_BRANCH}", credentialsId: 'github-credentials', url: "${GIT_REPO}"
            }
        }

        stage('Build and Push Image with Kaniko') {
            steps {
                container('kaniko') {
                    sh '''
                    /kaniko/executor \
                      --context "${WORKSPACE}/django" \
                      --dockerfile "${WORKSPACE}/django/Dockerfile" \
                      --destination "${IMAGE_REPO}:${IMAGE_TAG}" \
                      --destination "${IMAGE_REPO}:latest" \
                      --cache=true
                    '''
                }
            }
        }

        stage('Update Helm Values') {
            steps {
                container('git') {
                    sh '''
                    sed -i "s|repository: .*|repository: ${IMAGE_REPO}|" ${VALUES_FILE}
                    sed -i "s|tag: .*|tag: ${IMAGE_TAG}|" ${VALUES_FILE}

                    echo "Updated values.yaml:"
                    cat ${VALUES_FILE}
                    '''
                }
            }
        }

        stage('Commit and Push Changes') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-credentials', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_TOKEN')]) {
                    container('git') {
                        sh '''
                        git config --global user.email "jenkins@local"
                        git config --global user.name "Jenkins"
                        git config --global --add safe.directory "${WORKSPACE}"

                        git -C "${WORKSPACE}" add "${VALUES_FILE}"
                        git -C "${WORKSPACE}" commit -m "Update image tag to ${IMAGE_TAG}" || echo "No changes to commit"

                        git -C "${WORKSPACE}" push https://${GIT_USERNAME}:${GIT_TOKEN}@github.com/novikor-goit/devops-ci-cd.git HEAD:${GIT_BRANCH}
                        '''
                    }
                }
            }
        }
    }
}
