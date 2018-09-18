/*
  Copyright © 2018 Booz Allen Hamilton. All Rights Reserved.
  This software package is licensed under the Booz Allen Public License. The license can be found in the License file or at http://boozallen.github.io/licenses/bapl
*/

jenkins_openshift_project = "oc whoami".execute()
jenkins_openshift_project.waitFor()
project_name = jenkins_openshift_project.text.split(":").getAt(2)

//end new code
organizationFolder("Sample") {
  displayName("Sample")
  projectFactories{}
  configure{
    it / navigators << 'org.jenkinsci.plugins.github__branch__source.GitHubSCMNavigator'{
      repoOwner 'terrana-steven'
      scanCredentialsId "github"
      checkoutCredentialsId 'SAME'
      apiUri "https://github.boozallencsn.com/api/v3"
      pattern "sample-app"
      buildOriginBranch true
      buildOriginBranchWithPR false
      buildOriginPRMerge true
      buildOriginPRHead false
      buildForkPRMerge false
      buildForkPRHead false
    }
    it / projectFactories << "org.jenkinsci.plugins.pipeline.multibranch.defaults.PipelineMultiBranchDefaultsProjectFactory"{
  	  scriptPath "Jenkinsfile"
    }
  }
}
