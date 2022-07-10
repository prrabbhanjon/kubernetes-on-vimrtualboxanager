# Kubernetes-on-vimrtualboxmanager

**How to install kubernetes on virtualbox VMs.**

This tutorial provides a walkthrough of the how to setup the Kubernetes cluster orchestration in your system. Each module contains some background information on major Kubernetes master and woker nodes configuration and includes an interactive tutorial. These interactive tutorials let you manage a simple cluster and its containerized applications for yourself.

Using the interactive tutorials, you can learn to:

Deploy a containerized application on a cluster.
Scale the deployment.
Update the containerized application with a new software version.
Debug the containerized application.

here are several Kubernetes installation tools provided by various vendors. In this lab we will learn to use kubeadm. As a community-supported independent tool, it is planned to become the primary manner to build a Kubernetes cluster.


### Platforms: GCP, AWS, VirtualBox, etc.

The labs were written using Ubuntu instances running on Google Cloud Platform (GCP). They have been written to
be vendor-agnostic so could run on AWS, local hardware, or inside of virtualization to give you the most flexibility and
options. Each platform will have different access methods and considerations. As of v1.19.0 the minimum (as in barely
works) size for VirtualBox is 3vCPU/4G memory/5G minimal OS for cp and 1vCPU/2G memory/5G minimal OS for
worker node. Most other providers work with 2CPU/7.5G.


If using your own equipment you will have to disable swap on every node. There may be other requirements which will be shown as warnings or errors when using the kubeadm command. While most commands are run as a regular user, there are some which require root privilege. Please configure sudo access as shown in a previous lab. You If you are accessing the nodes remotely, such as with GCP or AWS, you will need to use an SSH client such as a local terminal or PuTTY if not using Linux or a Mac. You can download PuTTY from www.putty.org. You would also require a .pem or .ppk file to access the nodes. Each cloud provider will have a process to download or create this file. If attending in-person instructor led training the file will be made available during class.

### Very importanant note

Please disable any firewalls while learning Kubernetes. While there is a list of required ports for communication between
components, the list may not be as complete as necessary. If using GCP you can add a rule to the project which allows
all traffic to all ports. Should you be using VirtualBox be aware that inter-VM networking will need to be set
to promiscuous mode.

In the following exercise we will install Kubernetes on a single node then grow the cluster, adding more compute resources. Both nodes used are the same size, providing 2 vCPUs and 7.5G of memory. Smaller nodes could be used, but would run slower, and may have strange errors.

# Install Kubernetes - PC/Mac

This following steps to be required how to create a Kubernetes Lab on VirtualBox VMs. The steps to install VirtualBox, detail steps on how to create the VirtualBox VM and Guest OS installation are not covered. The VM OS will use Ubuntu-server 18.04 LTS.
You may change the network or IP addresses as per your network plan.

Download ISO: ubuntu-18.04-server-amd64.iso
Linux OS: Ubuntu 18.04 LTS, VERSION="18.04 LTS (Bionic Beaver)"
Note:
"While Ubuntu 18 bionic has become the typical version to deploy, the Kubernetes repository does not yet have matching binaries at the time of this writing. The xenial binaries can be used until an update is provided."

# Preperation
Create host-only network on VirtualBox, for example: vboxnet0 use IPv4 network address 192.168.70.0 (GW address: 192.168.70.1) and subnet 24 (Netmask: 255.255.255.0)
Create 3 VMs with 2 vCPU, 4096GB RAM each (for lower spec system, you can cut the spec to half), 100GB storage. These VMs will be named as:

<ul> <li>  Master-node </li>
<li>   Worker1-node </li> 
<li> Woker2-node </li> 
</ul>

## <a href="https://ubuntu.com/tutorials/install-ubuntu-desktop#1-overview">Install Ubuntu OS</a>

Post Install Steps.

<ul> Attach 2 network interfaces on every VM:
<li>NIC #1 uses bridge adapter, will be used for external connectivity. In this instruction, it is assumed that the external network is using network adress: 192.168.0.0/24. Where master-node will have static IP 192.168.0.10, worker01 will use 192.168.0.11 and worker02 will use 192.168.0.12. </li>
Note: 
You may opt to NAT and VirtualBox port forwarding feature to SSH to the VM.

<li> NIC #2 usses host-only vboxnet0, will be used for internal connectivity
Attach the ubuntu-18.04-server-amd64.iso  to each VM </li></ul>


<pre class="notranslate"><code> # vi /etc/netplan/01-netcfg.yaml 

network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: no
      addresses:
        - 192.168.0.10/24
      gateway4: 192.168.0.1
      nameservers:
          addresses: [8.8.8.8, 1.1.1.1]        
    enp0s8:
      dhcp4: no
      addresses:
        - 192.168.70.3/24
      gateway4: 192.168.70.1 
      
Please note virtual box master, 2 worker nodes ip address must be  diff ips not same ips. </code> </pre>

<h1> Configure below steps for 3 machines  same master, woker-1 and woker-2 nodes </h2>


<ul> <li> # sudo hostnamectl set-hostname your-host-name </li> </ul>
For example
<ul> <li># sudo hostnamectl set-hostname master-node </li> </ul>
Become root and update and upgrade the system. You may be asked a few questions. Allow restarts and keep the local version currently installed. Which would be a yes then a 
   <ul> <li># apt-get update && apt-get upgrade -y </li> </ul> 
Restart services during package upgrades without asking? [yes/no] yes
<ul> <li> Install a text editor like nano, vim, or emacs. Any will do, the labs use a popular option, vim. </li></ul> 
root@cp:˜# apt-get install -y vi
<ul> <li>The main choices for a container environment are Docker r and cri-o. We suggest Docker for class, as cri-o is not yet the default when building the cluster with kubeadm on Ubuntu. The cri-o engine is the default in Red Hat products and is being implemented by others. Installing Docker is a single command. At the moment it takes several steps to install and configure crio. Also the cluster node name may be set differently depending on what you put in the cluster configuration files. </li> </ul> 
<h1> very important: if you want extra challenge use cri-o. Otherwise install Docker </h1>
<ul> <li> Please note, install Docker OR cri-o. If both are installed the kubeadm init process search pattern will use Docker. Also be aware that if you choose to use crio you may find encounter different output than shown in the book </li> </ul>

<ul> <li>  (a) If using Docker: </li </ul>
root@cp:˜# apt-get install -y docker.io
<ul> <li> Add a new repo for kubernetes. You could also download a tar file or use code from GitHub. Create the file and add an entry for the main repo for your distribution. We are using the Ubuntu 18.04 but the kubernetes-xenial repo of the software, also include the key word main. Note there are four sections to the entry.</li> </ul> 
root@cp:˜# echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list 

 <ul> <li>   Add a GPG key for the packages. The command spans three lines. You can omit the backslash when you type. The OK is the expected output, not part of the command.</li> </ul> 
root@cp:˜# curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
   <ul> <li>   Update with the new repo declared, which will download updated repo information. </li> </ul> 
   root@cp:˜# apt-get update
<ul> <li>    Install the software. There are regular releases, the newest of which can be used by omitting the equal sign and version information on the command line. Historically new versions have lots of changes and a good chance of a bug or five. As a result we will hold the software at the recent but stable version we install. In a later lab we will update the cluster to anewer version.</li> </ul> 
  #apt-get install -y kubeadm=1.21.1-00 kubelet=1.21.1-00 kubectl=1.21.1-00
  root@cp:˜# apt-mark hold kubelet kubeadm kubectl
1 kubelet set on hold.
2 kubeadm set on hold.
3 kubectl set on hold.

  <h2> Configurartion on Master server only  </h2>
  
<ul> <li>    Deciding which pod network to use for Container Networking Interface (CNI) should take into account the expected demands on the cluster. There can be only one pod network per cluster, although the CNI-Genie project is trying to change this.</li> </ul> 
<ul> <li>   The network must allow container-to-container, pod-to-pod, pod-to-service, and external-to-service communications. As Docker uses host-private networking, using the docker0 virtual bridge and veth interfaces would require being on that host to communicate.</li> </ul> 
<ul> <li>   We will use Calico as a network plugin which will allow us to use Network Policies later in the course. Currently Calico does not deploy using CNI by default. Newer versions of Calico have included RBAC in the main file. Once downloaded look for the expected IPV4 range for containers to use in the configuration file.</li> </ul> 
  
  master@cp:˜# wget https://docs.projectcalico.org/manifests/calico.yaml
<ul> <li> Use less to page through the file. Look for the IPV4 pool assigned to the containers. There are many different configuration settings in this file. Take a moment to view the entire file. The CALICO_IPV4POOL_CIDR must match the value given to kubeadm init in the following step, whatever the value may be. Avoid conflicts with existing IP ranges of the instance. </li> </ul> 
root@cp:˜# less calico.yaml
  
  <pre class="notranslate"><code> ....
    2 # The default IPv4 pool to create on startup if none exists. Pod IPs will be
    3 # chosen from this range. Changing this value after installation will have
    4 # no effect. This should fall within `--cluster-cidr`.
    5 # name: CALICO_IPV4POOL_CIDR
    6 # value: "192.168.0.0/16" </code> </pre>
  
  <ul> <li>  . Find the IP address of the primary interface of the cp server. The example below would be the ens4 interface and an IP of 10.128.0.3, yours may be different. There are two ways of looking at your IP addresses </li> </ul> 
  <pre class="notranslate"><code> root@cp:˜# hostname -i
192.168.1.60 --> Master server IP eg:</code> </pre>
  
 <pre class="notranslate"><code> root@cp:˜# ip addr show 1 ....
2 2: ens4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1460 qdisc mq state UP group default qlen 1000
3 link/ether 42:01:0a:80:00:18 brd ff:ff:ff:ff:ff:ff
4 inet 10.128.0.3/32 brd 10.128.0.3 scope global ens4
5 valid_lft forever preferred_lft forever
6 inet6 fe80::4001:aff:fe80:18/64 scope link
7 valid_lft forever preferred_lft forever
8 ....</code> </pre>

<pre class="notranslate"><code>  Add an local DNS alias for our cp server. Edit the /etc/hosts file and add the above IP address and assign a name
k8scp.
root@cp:˜# vim /etc/hosts
192.168.1.60 k8scp #<-- Add this line on masster server only
127.0.0.1 localhost </code> </pre>

<ul> <li>  Create a configuration file for the cluster. There are many options we could include, and they differ for Docker and cri-o. For Docker we will only set the control plane endpoint, software version to deploy and podSubnet values. There are a lot more variables to set when using cri-o, such as the node name to use for the control plane, using the name: setting. Use the file included in the course tarball. After our cluster is initialized we will view other default values used. Be sure to use the node alias, not the IP so the network certificates will continue to work when we deploy a load balancer in a future lab. </li> </ul> 
IF USING DOCKER
<pre class="notranslate"><code> root@cp:˜# vim kubeadm-config.yaml #<-- Only for Docker
i apiVersion: kubeadm.k8s.io/v1beta2
2 kind: ClusterConfiguration
3 kubernetesVersion: 1.21.1 #<-- Use the word stable for newest version
4 controlPlaneEndpoint: "k8scp:6443" #<-- Use the node alias not the IP
5 networking:
6 podSubnet: 192.168.0.0/16 #<-- Match the IP range from the Calico config file </code> </pre>

<ul> <li>  Initialize the cp. Read through the output line by line. Expect the output to change as the software matures. At the end are configuration directions to run as a non-root user. The token is mentioned as well. This information can be found later with the kubeadm token list command. The output also directs you to create a pod network to the cluster, which will be our next step. Pass the network settings Calico has in its configuration file, found in the previous step. Please note: the output lists several commands which following exercise steps will complete. Note: Change the config file if you are using cri-o.  </li> </ul> 

<pre class="notranslate"><code> root@cp:˜# kubeadm init --config=kubeadm-config.yaml --upload-certs  | tee kubeadm-init.out # Save output for future review </code> </pre>

What follows is output of kubeadm init from Docker. Read the next step prior to further typing.

<pre class="notranslate"><code>  1 [init] Using Kubernetes version: v1.21.1
2 [preflight] Running pre-flight checks
3 [WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the
4 Docker cgroup driver. The recommended driver is "systemd".
5
6 <output_omitted>
7
8 You can now join any number of the control-plane node
9 running the following command on each as root:
10
11 kubeadm join k8scp:6443 --token vapzqi.et2p9zbkzk29wwth \
12 --discovery-token-ca-cert-hash sha256:f62bf97d4fba6876e4c3ff645df3fca969c06169dee3865aab9d0bca8ec9f8cd \
13 --control-plane --certificate-key 911d41fcada89a18210489afaa036cd8e192b1f122ebb1b79cce1818f642fab8
14
15 Please note that the certificate-key gives access to cluster sensitive
16 data, keep it secret!
17 As a safeguard, uploaded-certs will be deleted in two hours; If
18 necessary, you can use
19 "kubeadm init phase upload-certs --upload-certs" to reload certs afterward.
20
21 Then you can join any number of worker nodes by running the following
22 on each as root:
23
24 kubeadm join k8scp:6443 --token vapzqi.et2p9zbkzk29wwth \
25 --discovery-token-ca-cert-hash sha256:f62bf97d4fba6876e4c3ff645df3fca969c06169dee3865aab9d0bca8ec9f8cd  </code> </pre>

<ul> <li>  As suggested in the directions at the end of the previous output we will allow a non-root user admin level access to the cluster. Take a quick look at the configuration file once it has been copied and the permissions fixed.</ul> </li> 
root@cp:˜# exit

<pre class="notranslate"><code>  master@cp:˜$ mkdir -p $HOME/.kube
master@cp:˜$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
master@cp:˜$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
master@cp:˜$ less .kube/config
student@cp:˜$ less .kube/config
1 apiVersion: v1
2 clusters:
3 - cluster:
4 <output_omitted> </code> </pre>

<ul> <li>  Apply the network plugin configuration to your cluster. Remember to copy the file to the current, non-root user directory first  </ul> </li> 

<pre class="notranslate"><code>  master@cp:˜$ kubectl apply -f calico.yaml
1 configmap/calico-config created
2 customresourcedefinition.apiextensions.k8s.io/felixconfigurations.crd.projectcalico.org created
3 customresourcedefinition.apiextensions.k8s.io/ipamblocks.crd.projectcalico.org created
4 customresourcedefinition.apiextensions.k8s.io/blockaffinities.crd.projectcalico.org created
5 <output_omitted>  </code> </pre>
<ul> <li> While many objects have short names, a kubectl command can be a lot to type. We will enable bash auto-completion. Begin by adding the settings to the current shell. Then update the $HOME/.bashrc file to make it persistent. Ensure the bash-completion package is installed. If it was not installed, log out then back in for the shell completion to work. </ul> </li> 
<pre class="notranslate"><code>   master@cp:˜$ sudo apt-get install bash-completion -y
<exit and log back in>
master@cp:˜$ source <(kubectl completion bash)
master@cp:˜$ echo "source <(kubectl completion bash)" >> $HOME/.bashrc </code> </pre>

<ul> <li>  Test by describing the node again. Type the first three letters of the sub-command then type the Tab key. Auto-completion assumes the default namespace. Pass the namespace first to use auto-completion with a different namespace. By pressing Tab multiple times you will see a list of possible values. Continue typing until a unique name is used. First look at the current node (your node name may not start with cp), then look at pods in the kube-system namespace. If you see an error instead such as -bash: _get_comp_words_by_ref: command not found revisit the previous step, install the software, log out and back in. </ul> </li> 

<pre class="notranslate"><code>   master@cp:˜$ kubectl des<Tab> n<Tab><Tab> cp<Tab>
master@cp:˜$ kubectl -n kube-s<Tab> g<Tab> po<Tab>  </code> </pre>

<h3> View other values we could have included in the kubeadm-config.yaml file when creating the cluster </h3>
<pre class="notranslate"><code>  master@cp:˜$ sudo kubeadm config print init-defaults
1 apiVersion: kubeadm.k8s.io/v1beta2
2 bootstrapTokens:
3 - groups:
4 - system:bootstrappers:kubeadm:default-node-token
5 token: abcdef.0123456789abcdef
6 ttl: 24h0m0s
7 usages:
8 - signing
9 - authentication
10 kind: InitConfiguration <output_omitted>  </code> </pre>
