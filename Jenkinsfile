pipeline {
    agent {
        docker { image 'node:22.17.1-alpine3.22' }
    }
    stages {
        stage('Test') {
            steps {
                sh 'node --eval "console.log(process.platform,process.env.CI)"'
            }
        }
    }
}