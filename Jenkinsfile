pipeline {
    agent {
        docker {
            image 'my-playwright-app'
            reuseNode true
        }
    }

    environment {
        NETLIFY_SITE_ID = '1b0e8fe4-d807-4466-a7e4-986eb919922b'
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
        REACT_APP_VERSION = "1.0.${env.BUILD_ID}"
        CI_ENVIRONMENT_URL = 'https://ephemeral-mochi-43fc3e.netlify.app/'
    }

    stages {
        stage('AWS'){
            agent {
                docker {
                    image 'amazon/aws-cli'
                    command '/bin/bash'
                    reuseNode true
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'my-aws', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    sh '''
                        aws --version
                        aws s3 ls
                    '''
                }
            }
        }

        stage('Build & Unit Tests') {
            steps {
                sh '''
                    ls -la
                    node --version
                    npm --version
                    npm test
                '''
            }
            post {
                always {
                    junit 'jest-results/junit.xml'
                }
            }
        }

        stage('E2E Local') {
            agent {
                docker {
                    image 'my-playwright-app'
                    reuseNode true
                    args '--init --ipc=host --security-opt seccomp=seccomp_profile.json -v $PWD/seccomp_profile.json:/seccomp_profile.json'
                }
            }
            steps {
                sh '''
                    serve -s build > /dev/null 2>&1 &
                    sleep 30
                    npx playwright test --reporter=html
                '''
            }
            post {
                always {
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, icon: '', keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Playwright Local report', reportTitles: '', useWrapperFileDirectly: true])
                }
            }
        }

        stage('Deploy Staging') {
            steps {
                script {
                    sh '''
                        netlify --version
                        echo "Deploying to Staging. Site ID: ${NETLIFY_SITE_ID}"
                        netlify status
                        DEPLOY_OUTPUT=$(netlify deploy --dir=build --json)
                        echo "${DEPLOY_OUTPUT}" > deploy-output.json
                    '''
                    env.STAGING_URL = sh(script: "node-jq -r '.deploy_url' deploy-output.json", returnStdout: true).trim()
                    echo "Staging URL set to: ${env.STAGING_URL}"
                }
            }
        }

        stage('Staging E2E') {
            agent {
                docker {
                    image 'my-playwright-app'
                    reuseNode true
                    args '--init --ipc=host --security-opt seccomp=seccomp_profile.json -v $PWD/seccomp_profile.json:/seccomp_profile.json'
                }
            }

            environment {
                CI_ENVIRONMENT_URL = "${env.STAGING_URL}"
            }

            steps {
                sh '''
                    echo "Running E2E tests against staging environment: ${CI_ENVIRONMENT_URL}"
                    npx playwright test --reporter=html
                '''
            }

            post {
                always {
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Staging E2E', reportTitles: '', useWrapperFileDirectly: true])
                }
            }
        }

        stage('Approval') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    input message: 'Do you wish to deploy to production?', ok: 'Yes, I am sure!'
                }
            }
        }

        stage('Deploy Production') {
            steps {
                sh '''
                    netlify --version
                    echo "Deploying to Production. Site ID: ${NETLIFY_SITE_ID}"
                    netlify status
                    netlify deploy --dir=build --prod
                '''
            }
        }

        stage('Production E2E') {
            agent {
                docker {
                    image 'my-playwright-app'
                    reuseNode true
                    args '--init --ipc=host --security-opt seccomp=seccomp_profile.json -v $PWD/seccomp_profile.json:/seccomp_profile.json'
                }
            }
            environment {
                CI_ENVIRONMENT_URL = "${env.CI_ENVIRONMENT_URL}"
            }
            steps {
                sh '''
                    echo "Running E2E tests against production environment: ${CI_ENVIRONMENT_URL}"
                    npx playwright test --reporter=html
                '''
            }
            post {
                always {
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Prod E2E', reportTitles: '', useWrapperFileDirectly: true])
                }
            }
        }
    }
}