#!/bin/bash

#Copyright © 2018 Booz Allen Hamilton. All Rights Reserved.
#This software package is licensed under the Booz Allen Public License. The license can be found here: http://boozallen.github.io/licenses/bapl

# Constants
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Helper Methods:
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


# parsing input arguments
while getopts "h p: e: i:" OPT; do
    case "$OPT" in
        p)
            if [ -z ${PREFIX+x} ]; then
                PREFIX="${OPTARG}"
            else
                echo "tenant prefix (-p) can only be used once."
                echo "see -h for help"
                exit 1
            fi
            ;;
        e)
            ENVS+=("${OPTARG}")
            ;;
        i)
            if [ -z ${IMAGE_PROJECT+x} ]; then
                IMAGE_PROJECT="${OPTARG}"
            else
                echo "image project (-i) can only be used once."
                echo "see -h for help"
                exit 1
            fi
            ;;
        \?|h)
            echo "script usage: "
            echo "  -p | set's the tenant prefix. "
            echo "  -e | define an app env. can be used multiple times."
            echo "  -i | defines the project images will be pushed to."
            echo ""
            echo "example: "
            echo "  ./provision_app_envs.sh -p rhs -e dev -e test -e staging -e prod -i red-hat-summit"
            echo ""
            echo "this example would create the following projects: "
            echo " 1) rhs-tiller     | tiller server for this tenant"
            echo " 2) red-hat-summit | project for storing pushed images"
            echo " 3) rhs-dev        | dev app environment "
            echo " 4) rhs-test       | test app environment"
            echo " 5) rhs-staging    | staging app environment"
            echo " 6) rhs-prod       | prod app environment"
            echo "where: "
            echo " 1) rhs-{dev,test,staging} can pull images from red-hat-summit"
            echo " 2) rhs-tiller can deploy resources to rhs-{dev,test,staging}"
            exit 1
            ;;
    esac
done

if [ -z ${PREFIX+x} ]; then
    echo "you must set the tenant prefix"
    exit 1
fi

if [ -z ${ENVS+x} ]; then
    echo "you must set at least one application environment"
    exit 1
fi

if [ -z ${IMAGE_PROJECT+x} ]; then
    echo "you must set the image project"
    exit 1
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

# Install tiller server
title "Install Tiller"

# create tiller project
if oc new-project $PREFIX-tiller > /dev/null; then
    pass "created project $PREFIX-tiller"
else
    fail "created project $PREFIX-tiller"
    exit 1
fi

# create sdp-tiller service account
if oc create serviceaccount tiller -n $PREFIX-tiller > /dev/null; then
    pass "service account tiller created"
else
    fail "service account tiller created"
    exit 1
fi

# install tiller
if helm init --tiller-namespace $PREFIX-tiller --service-account tiller --wait > /dev/null; then
    pass "tiller installed in $PREFIX-tiller"
else
    fail "tiller installed in $PREFIX-tiller"
    exit 1
fi

# give tiller sa permissions
if oc apply -f <(oc process -f $SCRIPT_DIR/tiller_role.yaml -p TILLER_NAMESPACE=$PREFIX-tiller) -n $PREFIX-tiller > /dev/null; then
    pass "tiller sa given permissions to $PREFIX-tiller"
else
    fail "tiller sa given permissions to $PREFIX-tiller"
    exit 1
fi

# create project where images will be stored
title "Create Image Repository Project"

if oc new-project $IMAGE_PROJECT > /dev/null; then
    pass "created project $IMAGE_PROJECT"
else
    fail "created project $IMAGE_PROJECT"
    exit 1
fi

# create application environments
title "Create Application Environment Projects"
for APP_ENV in "${ENVS[@]}"; do

    # create app env project
    if oc new-project $PREFIX-$APP_ENV > /dev/null; then
        pass "created app env: $PREFIX-$APP_ENV"
    else
        fail "created app env: $PREFIX-$APP_ENV"
        exit 1
    fi

    # let tiller deploy to app env
    if oc apply -f <(oc process -f $SCRIPT_DIR/project_tiller_role.yaml -p TILLER_NAMESPACE=$PREFIX-tiller -p PROJECT=$PREFIX-$APP_ENV) -n $PREFIX-$APP_ENV > /dev/null; then
        pass "$PREFIX-tiller sa given permissions to manage $PREFIX-$APP_ENV"
    else
        fail "$PREFIX-tiller sa given permissions to manage $PREFIX-$APP_ENV"
        exit 1
    fi

    # let project pull images from $IMAGE_PROJECT
    if oc policy add-role-to-user system:image-puller system:serviceaccount:$PREFIX-$APP_ENV:default -n $IMAGE_PROJECT > /dev/null; then
        pass "let $PREFIX-$APP_ENV pull images from $IMAGE_PROJECT"
    else
        fail "let $PREFIX-$APP_ENV pull images from $IMAGE_PROJECT"
        exit 1
    fi

done
