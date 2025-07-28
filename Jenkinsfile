pipeline {
    agent any

    environment {
        NETLIFY_SITE_ID = '1b0e8fe4-d807-4466-a7e4-986eb919922b'
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
        REACT_APP_VERSION = "1.0.${env.BUILD_ID}"
        CI_ENVIRONMENT_URL = 'https://ephemeral-mochi-43fc3e.netlify.app/' // Your production URL
    }

    stages {
        
        stage('Build & Unit Tests') {
            agent {
                docker {
                    image 'my-playwright-app'
                    reuseNode true
                    args '-u root'
                }
            }
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
                    args '-u root'
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
            agent {
                docker {
                    image 'my-playwright-app'
                    reuseNode true
                    args '-u root'
                }
            }

            steps {
                script {
                    sh '''
                        netlify --version
                        echo "Deploying to Staging. Site ID: ${NETLIFY_SITE_ID}"
                        netlify status
                        DEPLOY_OUTPUT=$(netlify deploy --dir=build --json)
                        echo "${DEPLOY_OUTPUT}" > deploy-output.json
                    '''
                    // Set STAGING_URL as an environment variable for subsequent stages
                    env.STAGING_URL = sh(script: "node-jq -r '.deploy_url' deploy-output.json", returnStdout: true).trim()
                    echo "Staging URL set to: ${env.STAGING_URL}"
                }
            }
        }

        stage('Staging E2E') {
            agent {
                docker {
                    image 'my-playwright-app' // Use the custom image with playwright installed
                    reuseNode true
                    args '-u root'
                }
            }

            environment {
                CI_ENVIRONMENT_URL = "${env.STAGING_URL}" // Use the dynamically deployed staging URL
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
            agent {
                docker {
                    image 'my-playwright-app'
                    reuseNode true
                    args '-u root'
                }
            }
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
                    image 'my-playwright-app' // Use the custom image with playwright installed
                    reuseNode true
                    args '-u root'
                }
            }
            environment {
                // CI_ENVIRONMENT_URL is already defined globally for production
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