## TOC

- [Description](#description)
- [State](#state)
- [Prequisites](#prequisites)
  - [Alpha](#alpha)
- [Instructions](#instructions)
  - [Generating ssh keypair](#generating-ssh-keypair)
  - [Creating EKS cluster](#creating-eks-cluster)
  - [Adjusting JupyterHub configuration](#adjusting-jupyterhub-configuration)
  - [Installing JupyterHub](#installing-jupyterhub)
  - [Accessing JupyterHub](#accessing-jupyterhub)
- [Updating and Cleaning up](#updating-and-cleaning-up)
- [TODO](#todo)
- [Authors. License](#authors-license)

## Description

This project aims to launch a JupyterHub as fast as possible,
and to save users' time by providing better interface between their
workstation and their base infrastructure. The project becomes more mature
when users would not have to do much work on their workstation.

## State

- [x] Alpha, devops experience level 1, user level 3. See also [TODO](#TODO).
    - [x] aws
- [ ] Beta, devops experience level 2, user level 2
    - [ ] script-based and/or docker-based installation
    - [ ] Cross-platform instructions/scripts (Windows, Linux, Mac)
- [ ] Beta2, devops experience
    - [ ] gcp
    - [ ] azure
    - [ ] bare metal platform
- [ ] SRE experience, user level 1
    - [ ] Web interface, click click click

## Prequisites

### Alpha

- [ ] Linux workstation
- [ ] Basic understanding of shell environment (shell, command invocation, shell history and logging)
- [ ] aws account with almost-full privilege and a working profile.
      In this documentation, we assume the profile is `test1`.

Local tools:

- [ ] `ssh` to generate node authentication data (should be part of your local workstation system package)
- [ ] `awscli` (`pip install awscli==1.25.76`)
- [ ] `eksctl` (https://github.com/weaveworks/eksctl/releases/download/v0.114.0/eksctl_Linux_amd64.tar.gz ; homepage: https://github.com/weaveworks/eksctl)
- [ ] `aws-iam-authenticator` (https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.5.9/aws-iam-authenticator_0.5.9_linux_amd64; homepage: https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html)
- [ ] `kubectl` (Installation: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [ ] `helm` (Installation: https://get.helm.sh/helm-v3.9.1-linux-amd64.tar.gz)

Please follow the upstream projects to learn how to install these tools.

## Instructions

### Generating ssh keypair

The setup will require the file `~/.ssh/id_rsa.*` by default.
If you already have these files please skip this step.

### Creating EKS cluster

Please have a quick look at the file [clusters/test1/eksctl.yaml](./clusters/test1/eksctl.yaml)
and adjust settings to fit in your plan.

```
$ export AWS_PROFILE=test1
$ eksctl create cluster --config-file=clusters/test1/eksctl.yaml --kubeconfig=clusters/test1/kubeconfig.yaml
```

This step takes about 20 minutes, so please prepare some coffee for yourself beforehand.

Once the command is done, please get the nodes for testing purpose.
Your command's output would be different from the following sample.

```
$ export KUBECONFIG=`pwd -P`/clusters/test1/kubeconfig.yaml
$ kubectl get nodes

ip-192-168-10-9.ap-southeast-1.compute.internal     Ready    <none>   3m8s    v1.21.14-eks-ba74326
ip-192-168-47-129.ap-southeast-1.compute.internal   Ready    <none>   3m11s   v1.21.14-eks-ba74326
```

### Adjusting JupyterHub configuration

The configuration file is [jupyterhub/test1.yaml](jupyterhub/test1.yaml).
Please focus on the most relevant items

- [ ] Storage size: `singleuser.storge.capacity`
- [ ] notebook base image: `singleuser.image.name`
- [ ] Basic authentication password: `hub.DummyAuthenticator.password`

Please don't change the ingress setting (`ingress.*`) during this phase.
There is a bug in the chart that doesn't allow whitelist setting to work correctly.

### Installing JupyterHub

Please pickup your jupyterhub version from https://jupyterhub.github.io/helm-chart/,
or from the following table. In the next sample command, the helm-chart version
is `1.2.0` that means the jupyterhub version 1.5.0 will be installed

```
Helm-chart version               jupyterhub version

2.0.0       09 September  2022   3.0.0
1.2.0       04 November   2021   1.5.0
1.1.4       28 October    2021   1.4.2
1.1.3       25 August     2021   1.4.2
1.1.2       05 August     2021   1.4.2
1.1.1       22 July       2021   1.4.2
1.1.0       21 July       2021   1.4.2
1.0.1       25 June       2021   1.4.1
1.0.0       09 June       2021   1.4.1
0.11.1      15 January    2021   1.3.0
0.11.0      14 January    2021   1.3.0
```

Now you're ready to install the hub:

```
$ export KUBECONFIG=`pwd -P`/clusters/test1/kubeconfig.yaml
$ helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
$ helm repo udpate
$ helm upgrade --cleanup-on-fail \
  --install test1 jupyterhub/jupyterhub \
  --namespace test1 \
  --create-namespace \
  --version=1.2.0 \
  --values jupyterhub/test1.yaml

Release "test1" does not exist. Installing it now.
NAME: test1
LAST DEPLOYED: 2030
NAMESPACE: test1
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing JupyterHub!
....
```

You can see new pods are created and running

```
$ kubectl get pods -n test1
```

### Accessing JupyterHub

Please open new shell's session and invoke the following command:

```
$ kubectl port-forward service/proxy-public -n test1 8080:80
```

then get back to the original shell's session, and then open from your browser

- [ ] http://localhost:8080
- [ ] or http://127.0.0.1:8080

When being asked for user authentication data please complete with

```
username:  test1
password:  verysecure
```

(or the password that you will have given in [jupyterhub/test1.yaml](jupyterhub/test1.yaml)).

Enjoy your new JupyterHub.

## Updating and cleaning up

- [ ] If you want to update jupyterhub after it's installed, you can adjust
      its configuration and invoke the same commad (`helm upgrade...`)
      as seen in [Installing JupyterHub](#installing-jupyterhub).
- [ ] If you want to adjust the EKS cluster configuration, please refer
      to `eksctl`'s homepage for more details.
- [ ] If you want to destroy everything after your test is done, you can try
      the following dangerous commands:

      $ export KUBECONFIG=`pwd -P`/clusters/test1/kubeconfig.yaml
      $ kubectl delete namespace test1
      $ eksctl delete cluster  --config-file clusters/test1/eksctl.yaml

## TODO

- [x] persistent storage
- [ ] database integration
- [ ] ingress
    - [ ] bug: ingress whitelist doesn't work
    - [x] set up and patch
- [ ] notebook sync
- [ ] ci/cd

## Authors. License

The project is released under the terms of a BSD-3 license.
Please see [LICENSE](LICENSE) for more details.

The original author is Ky-Anh Huynh.
