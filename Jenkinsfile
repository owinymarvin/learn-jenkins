pipeline {
    agent any
    environment {
        // enter the Project ID
        NETLIFY_SITE_ID = '1b0e8fe4-d807-4466-a7e4-986eb919922b'
        // enter the access token created. Also saved in the Jenkins credential manager
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
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
                            image 'mcr.microsoft.com/playwright:v1.54.0-noble' 
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            npm install serve
                            npx serve -s build &
                            sleep 10
                            npx playwright test --reporter=html
                        '''
                    }
                    post{
                        always {
                            publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, icon: '', keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Playwright HTML Report', reportTitles: '', useWrapperFileDirectly: true])
                        }
                    }
                }
            }
        }

        stage('Deploy') {
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
    }
}
