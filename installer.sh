#!/usr/bin/env bash

# Copyright © 2018 Booz Allen Hamilton. All Rights Reserved.
# This software package is licensed under the Booz Allen Public License. The license can be found in the License file or at http://boozallen.github.io/licenses/bapl

# Constants
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# if [ -z "$1" ]; then
#   DEPLOYMENT_NAME="sdp"
# else
#   DEPLOYMENT_NAME="$1"
# fi

# Helper Methods:
# pretty pass/fail notations
pass(){
    printf "\xE2\x9C\x94 $1 \n"
}
fail(){
    printf "\xE2\x9C\x97 $1 \n\n"
}


title(){
    for i in $(seq -2 $(echo "$1" | wc -c)); do printf "-"; done && printf "\n"
    echo "| $1 |"
    for i in $(seq -2 $(echo "$1" | wc -c)); do printf "-"; done && printf "\n"
}

GENERATE_SUBDOMAINS=0 #Setting default value

# parsing input arguments
while getopts "n: j: s: a h" OPT; do
  case "$OPT" in
    n)
      if [ -z ${DEPLOYMENT_NAME+x} ]; then
        DEPLOYMENT_NAME="${OPTARG}"
      else
        echo "deployment name (-n) can only be used once."
        echo "see -h for help"
        exit 1
      fi
      ;;

    j)
      if [ -z ${JENKINS_SUBDOMAIN+x} ]; then
        JENKINS_SUBDOMAIN="${OPTARG}"
      else
        echo "Jenkins subdomain (-j) can only be used once."
        echo "see -h for help"
        exit 1
      fi
      ;;

    s)
      if [ -z ${SONARQUBE_SUBDOMAIN+x} ]; then
        SONARQUBE_SUBDOMAIN="${OPTARG}"
      else
        echo "Sonarqube subdomain (-s) can only be used once."
        echo "see -h for help"
        exit 1
      fi
      ;;

    a)
      GENERATE_SUBDOMAINS=1
      ;;

    \?|h)
      echo "script usage: "
      echo "  -a | automatically generate subdomains for routes; overridden"
      echo "       by -j and -s options, and overrides helm values files"
      echo "  -h | displays this help message"
      echo "  -j | sets and overrides the subdomain for the Jenkins route"
      echo "  -n | sets the deployment name (default = \"sdp\")"
      echo "  -s | sets and overrides the subdomain for the Sonarqube route"
      echo ""
      echo "  example: "
      echo "  ./installer.sh -n my-sdp -a -j my-jenkins"
      echo ""
      echo "  This example would create the following projects: "
      echo ""
      echo "   1) \"my-sdp\", which contains Jenkins, as well as any"
      echo "      other services (sonarqube, selenium, etc.) for which"
      echo "      the \"enabled\" value was set to \"true\" in values.yaml"
      echo ""
      echo "   2) \"my-sdp-tiller\", which contains the tiller server"
      echo "      the SDP uses to its deployment and related services"
      echo "      on Openshift"
      exit 0
      ;;
    esac
done

#setting default values
if [ -z ${DEPLOYMENT_NAME+x} ]; then
  DEPLOYMENT_NAME="sdp"
fi

if [ -z ${JENKINS_SUBDOMAIN+x} ]; then
  JENKINS_SUBDOMAIN=""
fi

if [ -z ${SONARQUBE_SUBDOMAIN+x} ]; then
  SONARQUBE_SUBDOMAIN=""
fi

# -----------------------------
title "Validate Requirements"

# validate oc is installed
if command -v oc &> /dev/null; then
    pass "oc installed"
else
    fail  "oc installed"
    echo "OpenShift CLI required"
    echo "See: https://docs.openshift.com/container-platform/latest/cli_reference/get_started_cli.html"
    echo "for installation instructions"
    exit 1
fi

# validate user is logged into OpenShift
if oc version | grep Server &> /dev/null; then
    pass "logged in with oc"
else
    fail "logged in with oc"
    echo "You must be logged in with the OpenShift CLI"
    echo "Please run the oc login command from the OpenShift Web Console."
    exit 1
fi

# validate helm is installed
if command -v helm &> /dev/null; then
    pass "helm installed"
else
    fail "helm installed"
    echo "Helm CLI required"
    echo "See: https://docs.helm.sh/using_helm/#install-helm"
    echo "for installation instructions"
    exit 1
fi

# not support brownfield deployments.
# validate sdp-tiller and sdp projects don't exist
if oc get project $DEPLOYMENT_NAME-tiller &> /dev/null; then
    fail "project $DEPLOYMENT_NAME-tiller already exists"
    echo "Brownfield deployments not supported."
    echo "Uninstall existing infrastructure via: "
    echo "    oc delete project $DEPLOYMENT_NAME-tiller"
    exit 1
fi
if oc get project $DEPLOYMENT_NAME &> /dev/null; then
    fail "project $DEPLOYMENT_NAME already exists"
    echo "Brownfield deployments not supported."
    echo "Uninstall existing infrastructure via: "
    echo "    oc delete project $DEPLOYMENT_NAME"
    exit 1
fi

# -----------------------------
title "Install Tiller Server"

# create sdp-tiller project
if oc new-project $DEPLOYMENT_NAME-tiller  --display-name="$DEPLOYMENT_NAME Tiller Server" --description="Tiller Server to deploy sdp resources" > /dev/null; then
    pass "project $DEPLOYMENT_NAME-tiller created"
else
    fail "project $DEPLOYMENT_NAME-tiller created"
    exit 1
fi

# create sdp-tiller service account
if oc create serviceaccount tiller -n $DEPLOYMENT_NAME-tiller > /dev/null; then
    pass "service account tiller created"
else
    fail "service account tiller created"
    exit 1
fi

# install tiller server in sdp-tiller
if helm init --tiller-namespace $DEPLOYMENT_NAME-tiller --service-account tiller --wait > /dev/null; then
    pass "Helm installed in $DEPLOYMENT_NAME-tiller"
else
    fail "Helm installed in $DEPLOYMENT_NAME-tiller"
    exit 1
fi

# give tiller sa requisite permissions
if oc apply -f <(oc process -f $SCRIPT_DIR/resources/helm/tiller_role.yaml -p TILLER_NAMESPACE=$DEPLOYMENT_NAME-tiller) -n $DEPLOYMENT_NAME-tiller > /dev/null; then
    pass "tiller sa given permissions to $DEPLOYMENT_NAME-tiller"
else
    fail "tiller sa given permissions to $DEPLOYMENT_NAME-tiller"
    exit 1
fi

# -----------------------------
title "Prepare SDP Resources"

# create sdp project
if oc new-project $DEPLOYMENT_NAME  --display-name="$DEPLOYMENT_NAME - Solutions Delivery Platform" --description="CI/CD Tools for sdp" > /dev/null; then
    pass "project $DEPLOYMENT_NAME created"
else
    fail "project $DEPLOYMENT_NAME created"
    exit 1
fi

if oc apply -f <(oc process -f $SCRIPT_DIR/resources/helm/project_tiller_role.yaml -p TILLER_NAMESPACE=$DEPLOYMENT_NAME-tiller -p PROJECT=$DEPLOYMENT_NAME) -n $DEPLOYMENT_NAME > /dev/null; then
    pass "tiller sa given permissions to $DEPLOYMENT_NAME project"
else
    fail "tiller sa given permissions to $DEPLOYMENT_NAME project"
    exit 1
fi

# # create github secret
 if [ -z "$GH_USER" ] || [ -z "$GH_PAT" ]; then
   echo -n "Enter GitHub User: "
   read GH_USER

   echo -n "Enter GitHub Personal Access Token: "
   read -s GH_PAT
   echo
 fi

 if oc create secret generic github --from-literal=username="$GH_USER" --from-literal=password="$GH_PAT" > /dev/null; then
     pass "secret github created"
 else
     fail "secret github created"
 fi

 HELM_OPTIONS="--set jenkins.credentials.github.username=$GH_USER,jenkins.credentials.github.password=$GH_PAT,jenkins.credentials.github.id=github "

# give jenkins sa required permissions
if oc adm policy add-scc-to-user privileged -z jenkins -n $DEPLOYMENT_NAME > /dev/null; then
    pass "make jenkins sa privileged"
else
    fail "make jenkins sa privileged"
fi


if oc adm policy add-cluster-role-to-user system:image-builder system:serviceaccount:$DEPLOYMENT_NAME:jenkins > /dev/null; then

    pass "make jenkins sa image-pusher"
else
    fail "make jenkins sa image-pusher"
fi

# install SDP chart
title "Helm Install"


if [ ! "$JENKINS_SUBDOMAIN" = "" ]; then
  HELM_OPTIONS+="--set jenkins.subdomain=$JENKINS_SUBDOMAIN "
elif ([ "$JENKINS_SUBDOMAIN" = "" ] && [ "$GENERATE_SUBDOMAINS" = "1" ]); then
  JENKINS_SUBDOMAIN="jenkins-$DEPLOYMENT_NAME"
  HELM_OPTIONS+="--set jenkins.subdomain=$JENKINS_SUBDOMAIN "
fi

if [ ! "$SONARQUBE_SUBDOMAIN" = "" ]; then
  HELM_OPTIONS+="--set sonarqube.subdomain=$SONARQUBE_SUBDOMAIN "
elif ([ "$SONARQUBE_SUBDOMAIN" = "" ] && [ "$GENERATE_SUBDOMAINS" = "1" ]); then
  SONARQUBE_SUBDOMAIN="sonarqube-$DEPLOYMENT_NAME"
  HELM_OPTIONS+="--set sonarqube.subdomain=$SONARQUBE_SUBDOMAIN "
fi

if helm install $SCRIPT_DIR -n $DEPLOYMENT_NAME --tiller-namespace $DEPLOYMENT_NAME-tiller $HELM_OPTIONS; then
    pass "Solutions Delivery Platform Installed"
else
    fail "Solutions Delivery Platform Install Failed"
fi
