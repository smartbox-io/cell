pipeline {
  agent {
    label "docker"
  }
  parameters {
    string(name: "INTEGRATION_BRANCH", defaultValue: "master", description: "Integration project branch to build with")
  }
  stages {
    stage("Retrieve build environment") {
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
        stage("Style analysis") {
          steps {
            sh("docker run --rm smartbox/cell:${GIT_COMMIT} bundle exec rubocop --no-color -D")
          }
        }
        stage("Security analysis") {
          steps {
            sh("docker run --rm smartbox/cell:${GIT_COMMIT} bundle exec brakeman --no-color -zA")
          }
        }
        stage("Model specs") {
          steps {
            sh("docker run --rm -e COVERAGE=models -t smartbox/cell:${GIT_COMMIT} bundle exec rspec --no-color spec/models")
          }
        }
        stage("Request specs") {
          steps {
            sh("docker run --rm -e COVERAGE=requests -t smartbox/cell:${GIT_COMMIT} bundle exec rspec --no-color spec/requests")
          }
        }
        stage("Library specs") {
          steps {
            sh("docker run --rm -e COVERAGE=lib -t smartbox/cell:${GIT_COMMIT} bundle exec rspec --no-color spec/lib")
          }
        }
        stage("All specs") {
          steps {
            sh("docker run --rm -t smartbox/cell:${GIT_COMMIT} bundle exec rspec --no-color")
          }
        }
        stage("Integration tests") {
          steps {
            script {
              build job: "integration/${INTEGRATION_BRANCH}", parameters: [
                string(name: "CELL_BRANCH", value: GIT_BRANCH)
              ]
            }
          }
        }
      }
    }
    stage ("Build production image") {
      steps {
        script {
          docker.build("smartbox/cell:${GIT_COMMIT}-production", "-f Dockerfile.production .")
        }
      }
    }
    stage("Publish production image") {
      steps {
        script {
          docker.withRegistry("https://registry.hub.docker.com", "docker-hub-credentials") {
            docker.image("smartbox/cell:${GIT_COMMIT}-production").push("latest")
          }
        }
      }
    }
  }
}
