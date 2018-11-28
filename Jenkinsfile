///////////////////////////////////////////////////////////////////////
//
//  BUILD AND PUBLISH PIPELINE FOR THE QUANTUM PACKAGE
//
///////////////////////////////////////////////////////////////////////
def build_image
def changed_files
def commit_tag
def coverage_unit
def coverage_integration
def coverage_system
def credentials = usernamePassword(
  credentialsId: 'pypi.wizardsofindustry',
  usernameVariable: 'TWINE_USERNAME',
  passwordVariable: 'TWINE_PASSWORD'
)
def image_base
def image_name
def tags

// Defines all branches that may be published/deployed
// if they have specified a commit tag or are marked as
// always deploy in the project configuration.
def publishable = [
  'master'
]


pipeline {

  agent {
    label 'docker'
  }

  stages {
    stage('Setup') {
      steps {
        script {
          tags = []
          changed_files = sh(
            script: 'git diff --name-only HEAD^1',
            returnStdout: true
          ).trim().tokenize('\n')
          for (i in changed_files) {
            echo "Detected change in ${i}"
          }

          // Ensure that all tags are fetched and assign it to a variable. Note
          // that if the branch contains multiple tags, the last one (as returned
          // by git tag -l) will be used.
          commit_tag = sh(
            returnStdout: true,
            script: "git tag -l --points-at HEAD | tail -1"
          ).trim()
          if (commit_tag) {
            sh "echo 'Commit tag is: ${env.GIT_BRANCH}/${commit_tag}'"
          }
        }
      }
    } // End setup stage

    stage('Build') {
      steps {
        script {
          // Ensure that the base image is up-to-date
          image_base = docker.image('wizardsofindustry/quantum-builder:python-3.6.5-slim-stretch')
          image_base.pull()

          // For libraries, the image that is built contains the environment
          // to run tests in.
          image_name = "quantum:${env.GIT_BRANCH}-${env.BUILD_ID}"
          image = docker.build(image_name)
        }
      }
    }

    stage('Run tests') {

      parallel {
        stage('Unit') {
          steps {
            script {
              image.inside("--entrypoint='' -v ${workspace}:/app -e BUILD_ID=${env.BUILD_ID}") {
                sh 'QUANTUM_TESTING_PHASE=unit ./bin/run-tests'
                if (fileExists("./.coverage.unit.${env.BUILD_ID}")) {
                  coverage_unit = readFile("./.coverage.unit.${env.BUILD_ID}")
                }
              }
            }
          }
        }

        stage('Integration') {
          steps {
            script {
              image.inside("--entrypoint='' -v ${workspace}:/app -e BUILD_ID=${env.BUILD_ID}") {
                sh 'QUANTUM_TESTING_PHASE=integration ./bin/run-tests'
                if (fileExists("./.coverage.integration.${env.BUILD_ID}")) {
                  coverage_integration = readFile("./.coverage.integration.${env.BUILD_ID}")
                }
              }
            }
          }
        }

        stage('System') {
          steps {
            script {
              image.inside("--entrypoint='' -v ${workspace}:/app -e BUILD_ID=${env.BUILD_ID}") {
                sh 'QUANTUM_TESTING_PHASE=system ./bin/run-tests'
                if (fileExists("./.coverage.system.${env.BUILD_ID}")) {
                  coverage_system = readFile("./.coverage.system.${env.BUILD_ID}")
                }
              }
            }
          }
        }
      }
    } // End tests

    stage('Check coverage') {

      parallel {
        stage('Python') {
          steps {
            script {
              image.inside("--entrypoint='' -v ${workspace}:/app -e BUILD_ID=${env.BUILD_ID}") {
                writeFile(
                  file: ".coverage.unit.${env.BUILD_ID}",
                  text: "${coverage_unit}"
                )
                writeFile(
                  file: ".coverage.integration.${env.BUILD_ID}",
                  text: "${coverage_integration}"
                )
                writeFile(
                  file: ".coverage.system.${env.BUILD_ID}",
                  text: "${coverage_system}"
                )
                sh 'coverage combine . && coverage report --fail-under 100 --omit **/test_*'
              }
            }
          }
        }
      }
    } // End coverage

    stage('Publish') {
      when {
        expression {
          return (!!commit_tag)
        }
      }
      parallel {

        stage('PyPI') {
          steps {
            script {
              image.inside() {
                withCredentials([credentials]) {
                  sh('python3 setup.py sdist bdist_wheel')
                  sh('twine upload dist/*')
                }
              }
            }
          }
        }
      }
    } // End publish
  }

  post {
    always {
      sh('make clean')
      sh("docker rmi -f ${image_name}")
    }
  }
}
