{{- /*
  Copyright © 2018 Booz Allen Hamilton. All Rights Reserved.
  This software package is licensed under the Booz Allen Public License. The license can be found here: http://boozallen.github.io/licenses/bapl
*/ -}}

{{/* Generate the Jenkins DSL Script to create credentials */}}
{{- define "jenkins.createCredentials" }}

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
import java.util.logging.Logger

def logger = Logger.getLogger("")
log = { message ->
  logger.info("${message}..")
}
{{- range .Values.credentials }}
log "Creating secret {{.id}}"
try{
  def username = {{ required "Required property .Values.credentials.username missing" .username | quote }}
  def password = {{ required "Required property .Values.credentials.password missing" .password | quote }}
  def credential_id = {{ required "Required property .Values.credentials.id missing" .id | quote }}
  def cred_obj = (Credentials) new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL,
    credential_id,
    credential_id,
    username,
    password
  )
  SystemCredentialsProvider.getInstance().getStore().addCredentials(Domain.global(), cred_obj)
}catch(any){}
{{- end }}

{{- end }}
