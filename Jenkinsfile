pipeline {
  agent {
    label "docker"
  }
  stages {
    stage("Retrieve build information") {
      steps {
        script {
          GIT_BRANCH = sh(returnStdout: true, script: "git rev-parse --abbrev-ref HEAD").trim()
          GIT_COMMIT = sh(returnStdout: true, script: "git rev-parse HEAD").trim()
        }
      }
    }
    stage("Build image") {
      steps {
        sh "docker build -t cell:${GIT_COMMIT} ."
      }
    }
    stage("Run static analysis") {
      parallel {
        stage("Run rubocop") {
          steps {
            sh "docker run --rm -i cell:${GIT_COMMIT} bundle exec rubocop -D"
          }
        }
        stage("Run brakeman") {
          steps {
            sh "docker run --rm -i cell:${GIT_COMMIT} bundle exec brakeman -zA"
          }
        }
      }
    }
    stage("Run specs") {
      steps {
        sh "docker run --rm -i cell:${GIT_COMMIT} bundle exec rspec spec"
      }
    }
  }
  post {
    always {
      sh "docker rmi -f cell:${GIT_COMMIT}"
    }
  }
}
