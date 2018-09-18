# Deploying Helm For Multitenancy on OpenShift

## Overview
To enable a multitenant OpenShift cluster, each organization must have its own tiller server.

The steps below will assume we're creating an instance of tiller for an org called cameo

## Steps
1. Create the tiller namespace
~~~ 
oc new-project tiller
~~~

2. Create a service account for tiller to use
~~~
oc create serviceaccount tiller 
~~~

3. Deploy tiller to the namespace using the serviceaccount
~~~
helm init --tiller-namespace tiller --service-account tiller
~~~

4. Give tiller service account permissions to create configmaps in the project and list namespaces
~~~
oc apply -f <(oc process -f tiller_role.yaml -p TILLER_NAMESPACE=tiller) -n tiller
~~~

5. Authorize tiller to deploy to projects: cameo-dev, cameo-prod
~~~
oc apply -f <(oc process -f project_tiller_role.yaml -p TILLER_NAMESPACE=tiller -p PROJECT=sdp) -n sdp
oc apply -f <(oc process -f project_tiller_role.yaml -p TILLER_NAMESPACE=tiller -p PROJECT=my-project) -n my-project
~~~
