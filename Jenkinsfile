pipeline {
  agent {
    label "jenkins-ruby"
  }
  environment {
    ORG = 'krishnakumar6893'
    APP_NAME = 'backend-master'
    CHARTMUSEUM_CREDS = credentials('jenkins-x-chartmuseum')
  }
  stages {
    stage('CI Build and push snapshot') {
      when {
        branch 'PR-*'
      }
      environment {
        PREVIEW_VERSION = "8.8.8"
        PREVIEW_NAMESPACE = "$APP_NAME-$BRANCH_NAME".toLowerCase()
        HELM_RELEASE = "$PREVIEW_NAMESPACE".toLowerCase()
      }
      steps {
        container('ruby') {
          sh "export VERSION=8.8.8 && skaffold build -f skaffold.yaml"
          sh "jx step post build --image $DOCKER_REGISTRY/$ORG/$APP_NAME:$PREVIEW_VERSION"
          dir('./charts/preview') {
            sh "make preview"
            sh "jx preview --app $APP_NAME --dir ../.."
          }
        }
      }
    }
    stage('Build Release') {
      when {
        branch 'master'
      }
      steps {
        container('ruby') {

          // ensure we're not on a detached head
          sh "git checkout master"
          sh "git config --global credential.helper store"
          sh "jx step git credentials"

          sh "jx step tag --version 8.8.8"
          sh "curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64"
          sh "chmod +x skaffold"
          sh "mv skaffold /usr/local/bin"
          sh "export VERSION=8.8.8 && skaffold build -f skaffold.yaml"
          sh "jx step post build --image $DOCKER_REGISTRY/$ORG/$APP_NAME:\$(cat VERSION)"
        }
      }
    }
    stage('Promote to Environments') {
      when {
        branch 'master'
      }
      steps {
        container('ruby') {
          dir('./charts/backend-master') {
            sh "jx step changelog --version v\$(cat ../../VERSION)"

            // release the helm chart
            sh "curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh"
            sh "chmod 700 get_helm.sh"
            sh "./get_helm.sh"
            sh "helm init"
            sh "helm repo add jenkins-x http://chartmuseum.jx.192.168.99.158.nip.io"
            sh "jx step helm release"

            // promote through all 'Auto' promotion Environments
            sh "jx promote -b --all-auto --timeout 1h --version 8.8.8"
          }
        }
      }
    }
  }
  post {
        always {
          cleanWs()
        }
  }
}
