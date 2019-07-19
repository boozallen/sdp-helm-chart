/*
  Copyright © 2018 Booz Allen Hamilton. All Rights Reserved.
  This software package is licensed under the Booz Allen Public License. The license can be found in the License file or at http://boozallen.github.io/licenses/bapl
*/

import jenkins.*
import hudson.*
import hudson.util.Secret
import hudson.model.*
import jenkins.model.*
import hudson.security.*
import jenkins.security.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*
import com.cloudbees.plugins.credentials.CredentialsProvider
import hudson.plugins.sshslaves.*
import org.openshift.jenkins.plugins.openshiftlogin.OpenShiftOAuth2SecurityRealm
import groovy.io.FileType
import javaposse.jobdsl.dsl.DslScriptLoader
import javaposse.jobdsl.plugin.JenkinsJobManagement
import java.util.logging.Logger
import org.jenkinsci.plugins.github_branch_source.GitHubConfiguration
import org.jenkinsci.plugins.github_branch_source.Endpoint

// for shared libraries
import org.jenkinsci.plugins.workflow.libs.GlobalLibraries
import org.jenkinsci.plugins.workflow.libs.LibraryConfiguration
import org.jenkinsci.plugins.workflow.libs.SCMSourceRetriever
import org.jenkinsci.plugins.workflow.libs.SCMRetriever
import org.jenkinsci.plugins.github_branch_source.GitHubSCMSource
import hudson.plugins.filesystem_scm.FSSCM
import hudson.security.*

// for security
import jenkins.security.s2m.AdminWhitelistRule
import hudson.security.csrf.DefaultCrumbIssuer
import org.jenkinsci.plugins.configfiles.groovy.GroovyScript
import org.jenkinsci.plugins.configfiles.GlobalConfigFiles
import org.jenkinsci.plugins.scriptsecurity.scripts.languages.GroovyLanguage
import jenkins.model.JenkinsLocationConfiguration
import org.jenkinsci.plugins.workflow.flow.FlowDurabilityHint

//for sonar installation
import hudson.plugins.sonar.SonarInstallation
import hudson.plugins.sonar.SonarRunnerInstallation
import hudson.plugins.sonar.SonarRunnerInstaller
import hudson.plugins.sonar.model.TriggersConfig
import hudson.tools.InstallSourceProperty


///////////////////
// Define Constants
///////////////////


////////////////

def logger = Logger.getLogger("")
log = { message ->
  logger.info("${message}..")
}

def jenkins = Jenkins.getInstance()


// CSN GitHub 
log "Creating Github Enterprise Endpoint for CSN"
List<Endpoint> endpointList = new ArrayList<Endpoint>()
endpointList.add(new Endpoint("https://github.boozallencsn.com/api/v3", "CSN GitHub"))
GlobalConfiguration.all().get(GitHubConfiguration.class).setEndpoints(endpointList)

// create jobs defined by JobDSL Scripts
log "Creating jobs from JobDSL Scripts in ${System.getenv("JENKINS_HOME")}/init.jobdsl.d"
def job_dsl = new File("${System.getenv("JENKINS_HOME")}/init.jobdsl.d")
if (job_dsl.exists()){
  def jobManagement = new JenkinsJobManagement(System.out, [:], new File("."))
  job_dsl.eachFileRecurse (FileType.FILES) { script ->
    log "  - ${script.name}"
    try{
      new DslScriptLoader(jobManagement).runScript(script.text)
    }catch(any){
      log "  ERROR: ${any}"
    }
  }
}

// optimize agents disconnecting post termination
log "Configuring optmized agent pod deregistration settings"
jenkins.injector.getInstance(hudson.slaves.ChannelPinger.class).@pingIntervalSeconds = 1
jenkins.injector.getInstance(hudson.slaves.ChannelPinger.class).@pingTimeoutSeconds = 10


// create initial admin user 
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin","admin")
jenkins.setSecurityRealm(hudsonRealm)
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(true)
Jenkins.instance.setAuthorizationStrategy(strategy)
jenkins.save()