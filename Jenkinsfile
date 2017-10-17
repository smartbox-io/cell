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
        script {
          docker.build("smartbox/cell:${GIT_COMMIT}")
        }
      }
    }
    stage("Analyze image") {
      parallel {
        stage("Coding style analysis") {
          steps {
            sh("docker run --rm -i smartbox/cell:${GIT_COMMIT} bundle exec rubocop -D")
          }
        }
        stage("Security analysis") {
          steps {
            sh("docker run --rm -i smartbox/cell:${GIT_COMMIT} bundle exec brakeman -zA")
          }
        }
        stage("Model specs") {
          steps {
            sh("docker run --rm -e COVERAGE=models -i smartbox/cell:${GIT_COMMIT} bundle exec rspec spec/models")
          }
        }
        stage("Request specs") {
          steps {
            sh("docker run --rm -e COVERAGE=requests -i smartbox/cell:${GIT_COMMIT} bundle exec rspec spec/requests")
          }
        }
        stage("All specs") {
          steps {
            sh("docker run --rm -i smartbox/cell:${GIT_COMMIT} bundle exec rspec")
          }
        }
      }
    }
    stage("Publish image") {
      steps {
        script {
          docker.withRegistry("https://registry.hub.docker.com", "docker-hub-credentials") {
            docker.image("smartbox/cell:${GIT_COMMIT}").push("latest")
          }
        }
      }
    }
  }
}
