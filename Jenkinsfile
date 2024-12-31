pipeline{
    agent any

    stages {
  stage('build-stage') {
    steps {
      echo 'building...'
    }

    agent any
  }

  stage('test-stage') {
    steps {
      echo 'testing...'
    }
  }

  stage('deploy-stage') {
    steps {
      echo 'deploying...'
    }
  }

}

}