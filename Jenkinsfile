// Jenkinsfile for VroongFriends iOS

pipeline {
    agent {
        label 'macos-m1'
    }

    environment {
        // Xcode version
        XCODE_VERSION = '16.2'

        // Fastlane
        LC_ALL = 'en_US.UTF-8'
        LANG = 'en_US.UTF-8'

        // Build settings
        WORKSPACE = 'VroongFriends.xcworkspace'
        SCHEME = 'VroongFriends'

        // Credentials
        APPLE_ID = credentials('apple-id')
        TEAM_ID = credentials('team-id')
        MATCH_PASSWORD = credentials('match-password')
        MATCH_GIT_URL = credentials('match-git-url')

        // Slack
        SLACK_WEBHOOK = credentials('slack-webhook-ios')
    }

    options {
        timestamps()
        timeout(time: 60, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '30'))
    }

    stages {
        stage('Setup') {
            steps {
                echo '🔧 Setting up environment...'
                sh '''
                    # Select Xcode version
                    sudo xcode-select -s /Applications/Xcode_${XCODE_VERSION}.app

                    # Install dependencies
                    bundle install
                    bundle exec pod install

                    # Setup Fastlane
                    bundle exec fastlane update_plugins
                '''
            }
        }

        stage('Lint') {
            steps {
                echo '🔍 Running SwiftLint...'
                sh 'bundle exec fastlane lint'
            }
        }

        stage('Test') {
            steps {
                echo '🧪 Running tests...'
                sh 'bundle exec fastlane test'
            }
            post {
                always {
                    // Publish test results
                    junit 'build/reports/junit.xml'

                    // Publish coverage
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'build/reports/coverage',
                        reportFiles: 'index.html',
                        reportName: 'Code Coverage'
                    ])
                }
            }
        }

        stage('Build') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                    branch pattern: 'release/.*', comparator: 'REGEXP'
                }
            }
            steps {
                echo '🔨 Building app...'
                script {
                    if (env.BRANCH_NAME == 'main') {
                        // Production build
                        sh 'bundle exec fastlane release'
                    } else {
                        // Beta build
                        sh 'bundle exec fastlane beta'
                    }
                }
            }
        }

        stage('Deploy') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }
            steps {
                echo '🚀 Deploying to TestFlight...'
                script {
                    if (env.BRANCH_NAME == 'main') {
                        echo 'Production deployment requires manual approval'
                        input message: 'Deploy to App Store?', ok: 'Deploy'
                    }
                }
            }
        }

        stage('Archive') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }
            steps {
                echo '📦 Archiving artifacts...'
                archiveArtifacts artifacts: 'build/**/*.ipa, build/**/*.dSYM.zip',
                                 fingerprint: true
            }
        }
    }

    post {
        success {
            echo '✅ Build successful!'
            script {
                if (env.BRANCH_NAME == 'develop' || env.BRANCH_NAME == 'main') {
                    slackSend(
                        color: 'good',
                        message: """
                            ✅ *Build Successful*
                            Job: ${env.JOB_NAME}
                            Build: ${env.BUILD_NUMBER}
                            Branch: ${env.BRANCH_NAME}
                            [View Build](${env.BUILD_URL})
                        """,
                        channel: '#ios-builds',
                        webhookUrl: env.SLACK_WEBHOOK
                    )
                }
            }
        }

        failure {
            echo '❌ Build failed!'
            slackSend(
                color: 'danger',
                message: """
                    ❌ *Build Failed*
                    Job: ${env.JOB_NAME}
                    Build: ${env.BUILD_NUMBER}
                    Branch: ${env.BRANCH_NAME}
                    [View Build](${env.BUILD_URL})
                """,
                channel: '#ios-builds',
                webhookUrl: env.SLACK_WEBHOOK
            )
        }

        always {
            echo '🧹 Cleaning up workspace...'
            cleanWs()
        }
    }
}

// Helper functions
def getVersionNumber() {
    return sh(
        script: "agvtool what-marketing-version -terse1",
        returnStdout: true
    ).trim()
}

def getBuildNumber() {
    return sh(
        script: "agvtool what-version -terse",
        returnStdout: true
    ).trim()
}