# Copyright © 2018 Booz Allen Hamilton. All Rights Reserved.
# This software package is licensed under the Booz Allen Public License. The license can be found in the License file or at http://boozallen.github.io/licenses/bapl

FROM jenkins/jenkins:2.121.3

ENV JAVA_OPTS "-Djenkins.install.runSetupWizard=false"

EXPOSE 8080
EXPOSE 50000

USER root

# install oc client
RUN mkdir -p /tmp/oc-client && cd /tmp/oc-client && \
    wget -O oc-client.tar.gz https://github.com/openshift/origin/releases/download/v3.6.1/openshift-origin-client-tools-v3.6.1-008f2d5-linux-64bit.tar.gz && \
    tar -xvf oc-client.tar.gz && \
    mv */oc /usr/bin/oc

# install plugins
COPY resources/plugins/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# insert configuration script
COPY resources/scripts/configure.groovy /var/jenkins_home/init.groovy.d/configure.groovy
RUN chmod 777 /var/jenkins_home/init.groovy.d/*

# insert job dsl scripts
RUN mkdir -p /var/jenkins_home/init.jobdsl.d
COPY resources/jobs/* /var/jenkins_home/init.jobdsl.d/
RUN chmod 777 /var/jenkins_home/init.jobdsl.d/*

# insert SDP entrypiont
COPY resources/scripts/sdp_entrypoint.groovy /usr/share/jenkins/ref/sdp_entrypoint.groovy

# copy in custom common-workflow plugin
COPY resources/plugins/common-workflow.hpi /usr/share/jenkins/ref

# copy in entry point scripts
COPY resources/scripts/jenkins-preboot.sh /usr/local/bin/jenkins_preboot
COPY resources/scripts/jenkins.sh /usr/local/bin/jenkins.sh
RUN chmod +x /usr/local/bin/jenkins_preboot && chmod 777 /usr/local/bin/jenkins_preboot /usr/local/bin/jenkins.sh

# modify permissions for OpenShift
RUN chgrp -R 0 $JENKINS_HOME && \
    chmod -R g=u $JENKINS_HOME /etc/passwd
