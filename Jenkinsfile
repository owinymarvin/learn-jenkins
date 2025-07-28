pipeline {
    agent any
    environment {
        // enter the Project ID
        NETLIFY_SITE_ID = '1b0e8fe4-d807-4466-a7e4-986eb919922b'
        // enter the access token created. Also saved in the Jenkins credential manager
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
        // production url
        CI_ENVIRONMENT_URL = 'https://ephemeral-mochi-43fc3e.netlify.app/'
    }
    stages {
        stage('Build') {
            agent {
                docker { 
                    image 'node:18-alpine' 
                    reuseNode true
                }
            }
            steps {
                sh '''
                    ls -la
                    node --version
                    npm --version
                    npm ci
                    npm run build
                    ls -la
                '''
            }
        }
        stage('Tests') {
            parallel {
                stage('Unit tests') {
                    agent {
                        docker { 
                            image 'node:18-alpine' 
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            test -f 'build/index.html'
                            npm test
                        '''
                    }
                    post{
                        always {
                            junit 'jest-results/junit.xml'
                        }
                    }
                }
     
                stage('E2E End To End ') {
                    agent {
                        docker { 
                            image 'mcr.microsoft.com/playwright:v1.39.0-jammy' 
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            npx serve -s build &
                            sleep 30
                            npx playwright test --reporter=html
                        '''
                    }
                    post{
                        always {
                            publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, icon: '', keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Playwright Local report', reportTitles: '', useWrapperFileDirectly: true])
                        }
                    }
                }
            }
        }
        stage('Deploy staging') {
            agent {
                docker { 
                    image 'node:18-alpine' 
                    reuseNode true
                }
            }
            steps {
                sh '''
                    npx netlify --version
                    echo "Deploying to Production, Project ID $NETLIFY_SITE_ID"
                    npx netlify status
                    npx netlify deploy --dir=build --json > deploy-output.json
                    echo 'added small changes'
                    npx node-jq -r '.deploy_url' deploy-output.json
                '''
                script {
                    env.STAGING_URL = sh(script: "npx node-jq -r '.deploy_url' deploy-output.json", returnStdout: true)
                }
            }
        }
        stage('Staging E2E') {
            agent {
                docker {
                    image 'mcr.microsoft.com/playwright:v1.39.0-jammy'
                    reuseNode true
                }
            }

            environment {
                CI_ENVIRONMENT_URL = "${env.STAGING_URL}"
            }

            steps {
                sh '''
                    npx playwright test  --reporter=html
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
            agent {
                docker { 
                    image 'node:18-alpine' 
                    reuseNode true
                }
            }
            steps {
                sh '''
                    npx netlify --version
                    echo "Deploying to Production, Project ID $NETLIFY_SITE_ID"
                    npx netlify status
                    npx netlify deploy --dir=build --prod
                '''
            }
        }
        stage('Production E2E ') {
            agent {
                docker { 
                    image 'mcr.microsoft.com/playwright:v1.39.0-jammy' 
                    reuseNode true
                }
            }
            environment {
                CI_ENVIRONMENT_URL = 'https://ephemeral-mochi-43fc3e.netlify.app/'
            }
            steps {
                sh '''
                    npx playwright test --reporter=html
                '''
            }
            post{
                always {
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Prod E2E', reportTitles: '', useWrapperFileDirectly: true])
                }
            }
        }
    }
}
