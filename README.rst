--------------------------
SDP Deployment Helm Charts
--------------------------

To deploy the `Solutions Delivery Platform`_:

============================================================
Configure the chart by customizing the ``values.yaml`` file.
============================================================

**********************
``values.yaml`` Fields
**********************

::

  # default values can be found in values.yaml for global values
  # or charts/${subchart}/values.yaml for subcharts' values.

  # Note that anything set in values.yaml takes priority over
  # what's set in any /charts/${subchart}/values.yaml files

  global:
    openshift:               String    True if deploying to Openshift
    persistentStorage:       Boolean   True if your cluster is configured for persistent storage
    domain:                  String    A domain managed by your router
    sourceRepositoryUrl:     String    A default github repository containing SDP image source code (i.e. this one)
    sourceSecret:            String    secret in "namespace" with credentials for "sourceRepositoryUrl"


  jenkins:
    domain:                  String       A domain managed by your router; overwrites the global value
    subdomain:               String       The prefix for your Jenkins URL (i.e. subdomain.example.com)
    masterDockerContextDir:  String       The directory containing your Jenkins-master source code
    agentDockerContextDir:   String       The directory containing your Jenkins-agent source code
    numAgents:               (+)Int       The number of Jenkins-agents to create
    sourceRepositoryUrl:     String       A default github repository containing SDP image source code (i.e. this one)
    sourceRepositoryBranch:  String       The branch of your context directories to use
    imageTag:                String       What to tag the Jenkins images (master/agent) you create as part of the install
    sourceSecret:            String       overwrites global.sourceSecret for the Jenkins source repositories
    credentials:             Map          See below
    resources:               Map          See below
    dockerStorage:           String       Sets the amount of storage reserved for the Jenkins-agents' docker daemon (only used if persistentStorage is true)
    dockerDaemonArgs:        string       Supplies args for the docker daemon running in the Jenkins agent (only used if persistentStorage is false)


  sonarqube:
    enabled:                 Boolean   Set to true if installing Sonarqube as part of the SDP installation
    domain:                  String    A domain managed by your router; overwrites the global value
    subdomain:               String    The prefix for your Sonarqube URL (i.e. subdomain.example.com)
    dockerContextDir:        String    The directory containing your Sonarqube source code
    sourceRepositoryUrl:     String    A github repository containing Sonarqube image source code; overwrites the global value
    imageTag:                String    What to tag the Sonarqube images (master/agent) you create as part of the install
    resources:               Map       See below



*******************
Configuring Jenkins
*******************

++++++++++++++++++++++
Credentials (Optional)
++++++++++++++++++++++

While the installation process automatically creates and stores the credentials
necessary for most users, you can set additional credentials you want available
to Jenkins. These can be credentials for different GitHub users, artifact
repositories, or services you wish to use as part of your CI/CD pipeline.

Any credentials you list here are automatically added to the Jenkins credential
store.

::

  jenkins:
    credentials:
    - id:        Required. Unique name for the credential by which it can be referenced
      username:  Required. The username for the credential
      password:  Required. The password for the credential
    - ... (multiple can be defined)

The credentials that are created automatically (**and should not be listed in the values file**) are:

* github: the GitHub credential supplied by the user during the installation
* openshift-service-account: the credentials for the jenkins ServiceAccount that Jenkins uses to authenticate to Openshift
* openshift-docker-registry: the same as above, but in a more convenient username/password format; use this for the sdp and docker SDP libraries
* sonarqube: credentials for interfacing w/ the Sonarqube server deployed alongside Jenkins

++++++++++++++++++++
Resources (Optional)
++++++++++++++++++++

Set the CPU and memory guarantees and limits. The requests ensure that containers
get adequate computing resources on whichever node they're scheduled on,
while the limits ensure containers are restarted and rescheduled should they begin
consuming too many resources. Together, this ensures quality of service for Jenkins
and the other containers on the cluster.

Note that you shouldn't need to configure this in order to set up SDP, as sensible
defaults have already been set.

More information on resource requests and limits can be found on the `Kubernetes website`_,
but note that users are currently restricted to placing requests and limits on cpu and memory.


::

  jenkins:
    resources:
      master:               Values for the Jenkins Master
        limits:             The resources the container can use before being evicted
          cpu:              Cpu limit
          memory:           Memory limit
        requests:           The node's necessary resources for a container to be scheduled
          cpu:              Requested CPUs
          memory:           Requested memory
      agent:                Values for the Jenkins Agent (structure same as above)
        limits:             The resources the container can use before being evicted
          cpu:              Cpu limit
          memory:           Memory limit
        requests:           The resources a node must have available before the container can be scheduled
          cpu:              Requested CPUs
          memory:           Requested memory

  sonarqube:
    resources:             Values for the Sonarqube container
      limits:              The resources the container can use before being evicted
        cpu:               Cpu limit
        memory:            Memory limit
      requests:            The resources a node must have available before the container can be scheduled
        cpu:               Requested CPUs
        memory:            Requested memory


+++++++++++++++++++++
Example Configuration
+++++++++++++++++++++

::

  global:
    persistentStorage: true
    domain: apps.ocp.example.com

  jenkins:
    numAgents: 4

    #Github Username and Access Token
    credentials:
    - id: doe-john-github
      username: doe-john
      password: 1234abcd5678efgh

    # Computing Resource Guarantees and Limits
    # Requests and limits are equal to guarantee quality of service
    resources:
      master:
        limits:
          cpu: "1000m"
          memory: "3000Mi"
        requests:
          cpu: "1000m"
          memory: "3000Mi"
      agent:
        limits:
          cpu: "1000m"
          memory: "1500Mi"
        requests:
          cpu: "1000m"
          memory: "1500Mi"

  sonarqube:
    enabled: true
    resources:
      limits:
        cpu: "150m"
        memory: "2000Mi"
      requests:
        cpu: "150m"
        memory: "2000Mi"


========================
Run the Installer Script
========================

From your terminal, login to Openshift as a cluster-admin and run the installer
script.

.. code:: shell

    ./installer.sh

Supply a GitHub username and password (or access token) when prompted.

************************
Installer Script Options
************************

Run ``./installer.sh -h`` to view the installer script's options.

.. _Solutions Delivery Platform: https://boozallen.github.io/sdp-docs/
.. _Kubernetes website: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/
