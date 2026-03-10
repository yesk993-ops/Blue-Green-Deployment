pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
    }

    parameters {
        choice(name: 'DEPLOY_ENV', choices: ['blue','green'], description: 'Deploy environment')
        choice(name: 'DOCKER_TAG', choices: ['blue','green'], description: 'Docker image tag')
        booleanParam(name: 'SWITCH_TRAFFIC', defaultValue: false, description: 'Switch traffic')
    }

    environment {
        IMAGE_NAME = "mydocker3692/bankapp"
        TAG = "${params.DOCKER_TAG}"
        KUBE_NAMESPACE = "webapps"
        SCANNER_HOME = tool 'sonar-scanner'
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                credentialsId: 'github',
                url: 'https://github.com/yesk993-ops/Blue-Green-Deployment.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh """
                    ${SCANNER_HOME}/bin/sonar-scanner \
                    -Dsonar.projectKey=nodejsmysql \
                    -Dsonar.projectName=nodejsmysql \
                    -Dsonar.sources=. \
                    -Dsonar.java.binaries=.
                    """
                }
            }
        }

        stage('Trivy FileSystem Scan') {
            steps {
                sh "trivy fs ."
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${TAG} ."
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh "trivy image ${IMAGE_NAME}:${TAG}"
            }
        }

        stage('Docker Push') {
            steps {
                withDockerRegistry(credentialsId: 'docker') {
                    sh "docker push ${IMAGE_NAME}:${TAG}"
                }
            }
        }

        stage('Deploy MySQL') {
            steps {
                withKubeConfig(
                    credentialsId: 'k8-token',
                    namespace: "${KUBE_NAMESPACE}",
                    serverUrl: 'https://46743932FDE6B34C74566F392E30CABA.gr7.ap-south-1.eks.amazonaws.com'
                ) {
                    sh "kubectl apply -f mysql-ds.yml"
                }
            }
        }

        stage('Deploy Service') {
            steps {
                withKubeConfig(
                    credentialsId: 'k8-token',
                    namespace: "${KUBE_NAMESPACE}",
                    serverUrl: 'https://46743932FDE6B34C74566F392E30CABA.gr7.ap-south-1.eks.amazonaws.com'
                ) {
                    sh """
                    if ! kubectl get svc bankapp-service -n ${KUBE_NAMESPACE}; then
                        kubectl apply -f bankapp-service.yml
                    fi
                    """
                }
            }
        }

        stage('Deploy Blue or Green') {
            steps {
                script {

                    def deployFile = params.DEPLOY_ENV == "blue" ? 
                        "app-deployment-blue.yml" : 
                        "app-deployment-green.yml"

                    withKubeConfig(
                        credentialsId: 'k8-token',
                        namespace: "${KUBE_NAMESPACE}",
                        serverUrl: 'https://46743932FDE6B34C74566F392E30CABA.gr7.ap-south-1.eks.amazonaws.com'
                    ) {
                        sh "kubectl apply -f ${deployFile}"
                    }
                }
            }
        }

        stage('Switch Traffic') {
            when {
                expression { params.SWITCH_TRAFFIC == true }
            }

            steps {
                script {

                    def newEnv = params.DEPLOY_ENV

                    withKubeConfig(
                        credentialsId: 'k8-token',
                        namespace: "${KUBE_NAMESPACE}",
                        serverUrl: 'https://46743932FDE6B34C74566F392E30CABA.gr7.ap-south-1.eks.amazonaws.com'
                    ) {
                        sh """
                        kubectl patch service bankapp-service \
                        -p '{"spec":{"selector":{"app":"bankapp","version":"${newEnv}"}}}'
                        """
                    }

                    echo "Traffic switched to ${newEnv}"
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                withKubeConfig(
                    credentialsId: 'k8-token',
                    namespace: "${KUBE_NAMESPACE}",
                    serverUrl: 'https://46743932FDE6B34C74566F392E30CABA.gr7.ap-south-1.eks.amazonaws.com'
                ) {
                    sh """
                    kubectl get pods -l version=${params.DEPLOY_ENV} -n ${KUBE_NAMESPACE}
                    kubectl get svc bankapp-service -n ${KUBE_NAMESPACE}
                    """
                }
            }
        }
    }
}
