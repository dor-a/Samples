/* groovylint-disable DuplicateStringLiteral, GStringExpressionWithinString, LineLength, NestedBlockDepth, UnnecessaryGString */
/* groovylint-disable-next-line CompileStatic */
pipeline {
agent {
  kubernetes {
    cloud 'aks-cluster-01'
    inheritFrom 'dind'
    namespace 'jenkins-agents'
  }
}
options {
        ansiColor('xterm')
    }


environment {
  B_ENV = "${params.ENVIORMENT}"
  B_ID = "app_${params.ENVIORMENT}_${BUILD_NUMBER}" // every jenkins build the number increament by one 
  K8S_APP_NAME= "namespace-app--${params.ENVIORMENT}"
}
  stages {
    stage('Preping ENV') {
      steps {
        script {
                    if (env.B_ENV== 'qa') {
                        ACR_CREDENTIALS="acr-creds" // username and password of the acr (Azure Container Registry) located in Jenkins "Vault"
                        K8S_ID="test-aks-config" // k8s config file - in order to connect to the k8s cluster , located in jenkins "Vault"
                        APP_URL="test.site.com" // url of the app
                        K8S_REPLICAS="2"  // number of replicas (pods) to be created)                      
                        ENV_LOCATION="eu" // region of the k8s cluster
                    }

                }

        sh 'printenv'
      }
    }


    stage('Build Image') { // using dind which is a docker in docker container to build and tag the image
     steps {
       container('dind') {
          withCredentials([usernamePassword(credentialsId: "$ACR_CREDENTIALS", passwordVariable: 'ACR_PASSWD', usernameVariable: 'ACR_USR')]) {
          sh "docker login acr.azurecr.io --username $ACR_USR --password $ACR_PASSWD"}
          sh "docker image build --build-arg ARG_1=$ARG_1 --build-arg ARG_2=$ARG_2 --build-arg ENV=$B_ENV -f Dockerfile -t app:$B_ID ." // image name will be app:app_qa_1
          sh "docker image tag ui:$B_ID acr.azurecr.io'/app:$B_ID" // full image name will be acr.azurecr.io/ui:app_qa_1
          echo "Starting Push To ACR"
        }
      }
    }
        stage('Pushing Image') { // using dind which is a docker in docker container to push the image to the ACR
      steps {
        container('dind') {
          echo "Starting Push To ACR"
          withCredentials([usernamePassword(credentialsId: "$ACR_CREDENTIALS", passwordVariable: 'ACR_PASSWD', usernameVariable: 'ACR_USR')]){
          sh "docker login $ACR_USR'.azurecr.io' --username $ACR_USR --password $ACR_PASSWD"}
          sh "docker image push acr.azurecr.io'/app:$B_ID" // full image name will be acr.azurecr.io/ui:app_qa_1
        }
      }
    }

    stage('Deploy App'){ // using diffrent container as an agent to  deploy the app to the k8s cluster
    environment {ACR_IMG_URL="acr.azurecr.io/app:$B_ID"} // full image name will be acr.azurecr.io/ui:app_qa_1
      steps{
        container('k8s-runner'){
          sh 'printenv'
          sh """sed -i "s|K8S_APP_NAME|$K8S_APP_NAME|g" k8s.yaml""" // replace the variables in the k8s.yaml file value = namespace
          sh """sed -i "s|APP_URL|$APP_URL|g" k8s.yaml""" // replace the variables in the k8s.yaml file value = url of the app
          sh """sed -i "s|ACR_IMG_URL|$ACR_IMG_URL|g" k8s.yaml""" // replace the variables in the k8s.yaml file value = full image name
          sh """sed -i "s|K8S_APP_LOCATION|$ENV_LOCATION|g" k8s.yaml""" // replace the variables in the k8s.yaml file value = region of the k8s cluster
          sh """sed -i "s|K8S_REPLICAS|$K8S_REPLICAS|g" k8s.yaml""" // replace the variables in the k8s.yaml file value = number of replicas (pods) to be created
          sh "cat k8s.yaml"
          withKubeConfig([credentialsId: "$K8S_ID"]) { sh "kubectl apply -f k8s.yaml" }

        }
      }
    }
      stage('Flush Cache'){
       steps{
        container('az-runner'){
          sh 'sleep 30'
          sh """curl -X POST "https://api.cloudflare.com/client/v4/zones/xxxxxx/purge_cache" \
     -H "X-Auth-Email: user@user.ocm" \
     -H "Authorization: Bearer xxxxxxxx" \
     -H "Content-Type: application/json" \
     --data '{"purge_everything":true}'"""
        }
      }
    }
  }
}