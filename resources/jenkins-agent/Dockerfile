# Copyright © 2018 Booz Allen Hamilton. All Rights Reserved.
# This software package is licensed under the Booz Allen Public License. The license can be found in the License file or at http://boozallen.github.io/licenses/bapl

FROM docker:dind

ENV JENKINS_SWARM_VERSION 3.9
ENV JNLP_SLAVE_VERSION 3.9
ENV HOME /root
ENV JAVA_HOME /usr/lib/jvm/java

RUN mkdir -p /opt/jenkins-slave/bin ${HOME} && \
    apk add --no-cache curl openjdk8 git device-mapper openssl-dev build-base nss && \
    # install docker-compose
    apk add --no-cache py-pip curl supervisor libffi-dev python-dev && \
    pip install docker-compose && \
    # set PID max to 99999
    # bc of docker bug w/ 6 character pid
    echo "kernel.pid_max=99999" >> /etc/sysctl.d/00-alpine.conf

# Copy script
COPY jenkins-agent.sh /opt/jenkins-slave/bin/jenkins-slave
RUN chmod 777 /opt/jenkins-slave/bin/jenkins-slave && \
    chmod +x /opt/jenkins-slave/bin/jenkins-slave && \
    # Download plugin and modify permissions
    curl --create-dirs -sSLo /opt/jenkins-slave/bin/swarm-client-$JENKINS_SWARM_VERSION.jar http://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/$JENKINS_SWARM_VERSION/swarm-client-$JENKINS_SWARM_VERSION.jar && \ 
    curl --create-dirs -sSLo /opt/jenkins-slave/bin/slave.jar http://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/$JNLP_SLAVE_VERSION/remoting-$JNLP_SLAVE_VERSION.jar

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["/usr/bin/supervisord --configuration /etc/supervisor/conf.d/supervisord.conf"]