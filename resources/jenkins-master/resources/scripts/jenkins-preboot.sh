#!/bin/bash

# Copyright © 2018 Booz Allen Hamilton. All Rights Reserved.
# This software package is licensed under the Booz Allen Public License. The license can be found in the License file or at http://boozallen.github.io/licenses/bapl

# replace pipeline-pipeline-multibranch-defaults plugin with our common-workflow plugin
# rm -rf $JENKINS_HOME/plugins/pipeline-multibranch-defaults* # See below
# cp /usr/share/jenkins/ref/common-workflow.hpi $JENKINS_HOME/plugins - Removing 1/29/19 (K.O.)
cp /usr/share/jenkins/ref/jte.jpi $JENKINS_HOME/plugins
