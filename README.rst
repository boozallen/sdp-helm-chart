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
    subdomain:               String       The prefix for your Jenkins URL (i.e. subdomain.my-domain.com)
    masterDockerContextDir:  String       The directory containing your Jenkins-master source code
    agentDockerContextDir:   String       The directory containing your Jenkins-agent source code
    numAgents:               (Pos.) Int   The number of Jenkins-agents to create
    githubOrganizations:     Map          See below
    pipelineLibraries:       Map          See below
    sourceRepositoryUrl:     String       A default github repository containing SDP image source code (i.e. this one)
    sourceRepositoryBranch:  String       The branch of your context directories to use
    imageTag:                String       What to tag the Jenkins images (master/agent) you create as part of the install
    sourceSecret:            String       overwrites global.sourceSecret for the Jenkins source repositories
    resources:               Map          See below
    dockerStorage:           String       Sets the amount of storage reserved for the Jenkins-agents' docker daemon (only used if persistentStorage is true)
    dockerDaemonArgs:        string       Supplies args for the docker daemon running in the Jenkins agent (only used if persistentStorage is false)


  sonarqube:
    enabled:                 Boolean   Set to true if installing Sonarqube as part of the SDP installation
    domain:                  String    A domain managed by your router; overwrites the global value
    subdomain:               String    The prefix for your Sonarqube URL (i.e. subdomain.my-domain.com)
    dockerContextDir:        String    The directory containing your Sonarqube source code
    sourceRepositoryUrl:     String    A github repository containing Sonarqube image source code; overwrites the global value
    imageTag:                String    What to tag the Sonarqube images (master/agent) you create as part of the install
    resources:               Map       See below



*******************
Configuring Jenkins
*******************

++++++++++++++++++++
GitHub Organizations
++++++++++++++++++++

Set the GitHub Organization(s) to watch:

::

  jenkins:
    githubOrganizations:
    - name:         Required. The GitHub Organization For SDP To Serve
      displayName:  Required. The Jenkins Job Display Name
      credentialID: Required. The Jenkins Credential ID To Access This Organization
      apiUrl:       Required. The GitHub API URL
      repoPattern:  Optional. Regex of Repositories to watch. Default is ".*"
    - ... (multiple can be defined)

++++++++++++++++++
Pipeline Libraries
++++++++++++++++++

Set the Jenkins Pipeline Libraries.  This should minimally include your organization's
pipeline configuration repository.  You can also include any pipeline libraries that will
be used in addition to the SDP pipeline-framework monorepo.

::

  jenkins:
    pipelineLibraries:
    - name:               Required. Library ID to reference when loading
      githubApiUrl:       Required. GitHub API URL
      githubCredentialID: Required. Jenkins Credential ID to Access Library Repo
      org:                Required. Name of GitHub Organization Containing Library
      repo:               Required. Name of GitHub Repository
      implicit:           Optional. Whether to Load Library Implicitly. Default false.
      defaultVersion:     Optional. Default Branch of Library to Load. Default master.
    - ... (multiple can be defined)

+++++++++++
Credentials
+++++++++++

Set the credentials you want available to Jenkins and other components of SDP.
These can be credentials for


At minimum you need to include a github credential that can be used to read the
repositories in the Solutions-Delivery-Platform Github Organization. If those
credentials can't also be used to read the Pipeline Libraries and Github Organizations
you specify, then you will need to add additional credentials for those.

You need to give your default GitHub credential the id "github", as a GitHub
credential by that name is required to run the Jenkins pipeline. For this default
GitHub credential, the username should be your GitHub username, and the password
an access token for that account.

::

  jenkins:
    credentials:
    - id:        Required. Unique name for the credential by which it can be referenced
      username:  Required. The username for the credential
      password:  Required. The password for the credential
    - ... (multiple can be defined)

++++++++++++++++++++
Resources (Optional)
++++++++++++++++++++

Set the CPU and memory guarantees and limits. The requests ensure that containers
get adequate computing resources on whichever node they're scheduled on,
while the limits ensure containers are restarted and rescheduled should they begin
consuming too many resources. Together, this ensures quality of service for Jenkins
and the other containers on the cluster.

Note that you shouldn't need to configure this in order to set up SDP, as sensible
defaults have already been set as defaults.

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
    domain: apps.oscp.microcaas.net

  jenkins:
    masterDockerContextDir: resources/jenkins-master
    agentDockerContextDir: resources/jenkins-agent
    numAgents: 4

    # GitHub Orgs to watch
    githubOrganizations:
    - name: terrana-steven
      displayName: Steven Terrana
      credentialID: github
      apiUrl: "https://github.boozallencsn.com/api/v3"
    - name: Red-Hat-Summit
      displayName: Red Hat Summit
      credentialID: github
      apiUrl: "https://github.boozallencsn.com/api/v3"

    # Pipeline Configuration Repository
    pipelineLibraries:
    - name: red-hat-summit
      githubApiUrl: "https://github.boozallencsn.com/api/v3"
      githubCredentialID: github
      org: Red-Hat-Summit
      repo: pipeline-configuration

    #Github Username and Access Token
    credentials:
    - id: github
      username: doe-john
      password: 1234abcd5678efgh

    # Computing Resource Guarantees and Limits
    # Requests and limits are equal to guarantee quality of service
    resources:
      master:
        limits:
          cpu: "1500m"
          memory: "5000Mi"
        requests:
          cpu: "1500m"
          memory: "5000Mi"
      agent:
        limits:
          cpu: "1500m"
          memory: "5000Mi"
        requests:
          cpu: "1500m"
          memory: "5000Mi"

  sonarqube:
    enabled: true
    resources:
      limits:
        cpu: "1500m"
        memory: "5000Mi"
      requests:
        cpu: "1500m"
        memory: "5000Mi"


========================
Run the Installer Script
========================

.. code:: shell

    ./installer.sh





.. _Solutions Delivery Platform: https://pages.github.boozallencsn.com/solutions-delivery-platform/pipeline-framework/
.. _Kubernetes website: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/
