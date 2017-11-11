pipeline {
  agent {
    label "docker"
  }
  parameters {
    string(name: "CELL_COMMIT", defaultValue: "", description: "Force revision to this specific commit")
    booleanParam(name: "SKIP_INTEGRATION", defaultValue: false, description: "Whether integration should be skipped")
    string(name: "CELL_NUMBER", defaultValue: "1", description: "Integration. Number of cells to deploy")
  }
  stages {
    stage("Retrieve build environment") {
      steps {
        script {
          if (params.CELL_COMMIT) {
            GIT_COMMIT = params.CELL_COMMIT
            sh("git checkout -fb integration ${params.CELL_COMMIT}")
          }
        }
        script {
          GIT_COMMIT_MESSAGE = sh(returnStdout: true, script: "git rev-list --format=%B --max-count=1 ${GIT_COMMIT}").trim()
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
      }
    }
    stage ("Build production image") {
      steps {
        script {
          docker.build("smartbox/cell:${GIT_COMMIT}-production", "-f Dockerfile.production .")
        }
      }
    }
    stage ("Internal publish") {
      steps {
        script {
          docker.withRegistry("https://registry.smartbox.io/") {
            docker.image("smartbox/cell:${GIT_COMMIT}-production").push(GIT_COMMIT)
          }
        }
      }
    }
    stage("Run integration tests") {
      when { expression { !params.SKIP_INTEGRATION } }
      steps {
        script {
          build job: "integration/master", parameters: [
            text(name: "COMMIT_MESSAGE", value: GIT_COMMIT_MESSAGE),
            string(name: "CELL_COMMIT", value: GIT_COMMIT),
            string(name: "CELL_NUMBER", value: params.CELL_NUMBER)
          ]
        }
      }
    }
    stage("Publish") {
      when { expression { !params.SKIP_INTEGRATION } }
      steps {
        script {
          docker.withRegistry("https://registry.hub.docker.com", "docker-hub-credentials") {
            docker.image("smartbox/cell:${GIT_COMMIT}-production").push("latest")
          }
        }
      }
    }
  }
  post {
    always {
      sh("docker rmi -f --no-prune smartbox/cell:${GIT_COMMIT}")
      sh("docker rmi -f --no-prune smartbox/cell:${GIT_COMMIT}-production")
      sh("docker rmi -f --no-prune registry.smartbox.io/smartbox/cell:${GIT_COMMIT}")
    }
  }
}
