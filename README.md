# Kubernetes-on-virtualbox-manager

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

<h3> Very importanant note </h3> 

Please disable any firewalls while learning Kubernetes. While there is a list of required ports for communication between
components, the list may not be as complete as necessary. If using GCP you can add a rule to the project which allows
all traffic to all ports. Should you be using VirtualBox be aware that inter-VM networking will need to be set
to promiscuous mode.

In the following exercise we will install Kubernetes on a single node then grow the cluster, adding more compute resources. Both nodes used are the same size, providing 2 vCPUs and 7.5G of memory. Smaller nodes could be used, but would run slower, and may have strange errors.

<h3> Install Kubernetes - PC/Mac </h3>

This following steps to be required how to create a Kubernetes Lab on VirtualBox VMs. The steps to install VirtualBox, detail steps on how to create the VirtualBox VM and Guest OS installation are not covered. The VM OS will use Ubuntu-server 18.04 LTS.
You may change the network or IP addresses as per your network plan.

Download ISO: ubuntu-18.04-server-amd64.iso
Linux OS: Ubuntu 18.04 LTS, VERSION="18.04 LTS (Bionic Beaver)"
Note:
"While Ubuntu 18 bionic has become the typical version to deploy, the Kubernetes repository does not yet have matching binaries at the time of this writing. The xenial binaries can be used until an update is provided."

<h3>Preperation </h3>
Create host-only network on VirtualBox, for example: vboxnet0 use IPv4 network address 192.168.70.0 (GW address: 192.168.70.1) and subnet 24 (Netmask: 255.255.255.0)
Create 3 VMs with 2 vCPU, 4096GB RAM each (for lower spec system, you can cut the spec to half), 100GB storage. These VMs will be named as:

<ul> <li>  Master-node </li>
<li>   Worker1-node </li> 
<li> Woker2-node </li> 
</ul>

<h3> <a href="https://ubuntu.com/tutorials/install-ubuntu-desktop#1-overview">Install Ubuntu OS</a> </h3>

Post Install Steps.

<ul> Attach 2 network interfaces on every VM:
<li>NIC #1 uses bridge adapter, will be used for external connectivity. In this instruction, it is assumed that the external network is using network adress: 192.168.0.0/24. Where master-node will have static IP 192.168.0.10, worker01 will use 192.168.0.11 and worker02 will use 192.168.0.12. </li>
Note: 
You may opt to NAT and VirtualBox port forwarding feature to SSH to the VM.

<li> NIC #2 usses host-only vboxnet0, will be used for internal connectivity
Attach the ubuntu-18.04-server-amd64.iso  to each VM </li></ul>


<pre class="notranslate"><code> # vi /etc/netplan/01-netcfg.yaml 
# This file describes the network interfaces available on your system
# For more information, see netplan(5).
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: no
      addresses:
        - 192.168.1.141/24
      gateway4: 192.168.1.1
      nameservers:
          addresses: [8.8.8.8, 1.1.1.1]
    enp0s8:
      dhcp4: no
      addresses:
        - 192.168.0.3/16
      gateway4: 192.168.0.1

      
Please note virtual box master, 2 worker nodes ip address must be  diff ips not same ips. </code> </pre>

<h4> Ensure that master node must a default route on VM not duplicate route, need to remove duplicate route. For example: </h4>

<h3> Configure below steps for 3 machines  same master, woker-1 and woker-2 nodes </h3>
<pre class="notranslate"> root@master:~# ip r
default via 192.168.0.1 dev enp0s8 proto static  <--- not needed, remove it
default via 192.168.1.1 dev enp0s3 proto static
192.168.0.0/16 dev enp0s8 proto kernel scope link src 192.168.0.3
192.168.1.0/24 dev enp0s3 proto kernel scope link src 192.168.1.141
....
....
root@master:~# route del default enp0s8 </code> </pre>
<h4> Add this following service to remove the duplicated default route after reboot. </h4>
<pre class="notranslate"><code>cat << EOF | sudo tee /etc/systemd/system/cleanup-double-route.service
[Unit]
Description=Custom script, remove double default route on Ubuntu

[Service]
User=root
ExecStart=/bin/bash -c "route del default enp0s8"

[Install]
WantedBy=multi-user.target
EOF </code> </pre>

<h4> Start and enable the service. </h4>
<pre class="notranslate"><code># sudo system4ctl daemon-reload
# sudo systemctl restart cleanup-double-route.service
# sudo systemctl enable cleanup-double-route.service </code> </pre>
 
<pre class="notranslate"><code>  # sudo hostnamectl set-hostname your-host-name  </code> </pre>
For example
<pre class="notranslate"><code> sudo hostnamectl set-hostname master-node  </code> </pre>
Become root and update and upgrade the system. You may be asked a few questions. Allow restarts and keep the local version currently installed. Which would be a yes then a 
<h3> below is the manual procedure for 3 nodes configuration  or <a href="https://github.com/prrabbhanjon/kubernetes-on-virtualboxmanager/blob/main/scripts/k8s_ubuntu_all-nodes_install.sh"> download script </a> </h3>
   <pre class="notranslate"><code>  # apt-get update && apt-get upgrade -y  </code> </pre>
Restart services during package upgrades without asking? [yes/no] yes
<ul> <li> Install a text editor like nano, vim, or emacs. Any will do, the labs use a popular option, vim. </li></ul> 
<pre class="notranslate"><code> root@cp:˜# apt-get install -y vi  </code> </pre>
<ul> <li>The main choices for a container environment are Docker r and cri-o. We suggest Docker for class, as cri-o is not yet the default when building the cluster with kubeadm on Ubuntu. The cri-o engine is the default in Red Hat products and is being implemented by others. Installing Docker is a single command. At the moment it takes several steps to install and configure crio. Also the cluster node name may be set differently depending on what you put in the cluster configuration files. </li> </ul> 
<h3> very important: if you want extra challenge use cri-o. Otherwise install Docker </h3>
<ul> <li> Please note, install Docker OR cri-o. If both are installed the kubeadm init process search pattern will use Docker. Also be aware that if you choose to use crio you may find encounter different output than shown in the book </li> </ul>
 
<ul> <li>  (a) If using Docker: </li </ul> 
<pre class="notranslate"><code> root@cp:˜# apt-get install -y docker.io </code> </pre>
<ul> <li> Add a new repo for kubernetes. You could also download a tar file or use code from GitHub. Create the file and add an entry for the main repo for your distribution. We are using the Ubuntu 18.04 but the kubernetes-xenial repo of the software, also include the key word main. Note there are four sections to the entry.</li> </ul> 
<pre class="notranslate"><code>  root@cp:˜# echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list  </code> </pre>

 <ul> <li>   Add a GPG key for the packages. The command spans three lines. You can omit the backslash when you type. The OK is the expected output, not part of the command.</li> </ul> 
<pre class="notranslate"><code>  root@cp:˜# curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - </code> </pre>
   <ul> <li>   Update with the new repo declared, which will download updated repo information. </li> </ul> 
  <pre class="notranslate"><code>  root@cp:˜# apt-get update </code> </pre>
<ul> <li>    Install the software. There are regular releases, the newest of which can be used by omitting the equal sign and version information on the command line. Historically new versions have lots of changes and a good chance of a bug or five. As a result we will hold the software at the recent but stable version we install. In a later lab we will update the cluster to anewer version.</li> </ul> 
  <pre class="notranslate"><code> #apt-get install -y kubeadm=1.21.1-00 kubelet=1.21.1-00 kubectl=1.21.1-00 </code> </pre>
  root@cp:˜# apt-mark hold kubelet kubeadm kubectl
1 kubelet set on hold.
2 kubeadm set on hold.
3 kubectl set on hold. </code> </pre>

  <h3> Configurartion on Master server only  </h3>
  
<ul> <li>    Deciding which pod network to use for Container Networking Interface (CNI) should take into account the expected demands on the cluster. There can be only one pod network per cluster, although the CNI-Genie project is trying to change this.</li> </ul> 
<ul> <li>   The network must allow container-to-container, pod-to-pod, pod-to-service, and external-to-service communications. As Docker uses host-private networking, using the docker0 virtual bridge and veth interfaces would require being on that host to communicate.</li> </ul> 

<h4> Initializing Control-plane/Master Node </h4>
<ul> <li> Execute kubeadm init command on master node as root user </ul> </li>
<pre class="notranslate"><code> root@master:~# sudo kubeadm init --pod-network-cidr 10.211.0.0/16 --apiserver-advertise-address=192.168.1.141
[init] Using Kubernetes version: v1.24.2
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull' 
.....
..... 

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.1.141:6443 --token obsles.lior2sheyppod8u5 \
        --discovery-token-ca-cert-hash sha256:5cbcf6e488be01dc74b729bd61408a67f99511f3a4f9eb9a6ab6442839e97703 </code> </pre>
        
<h4> Note </h4> 
<ul> <li> 10.211.0.0/16 is the POD network CIDR. You can select whichever network address that fit your requirement. </li> </ul>
<ul> <li> 192.168.70.3 is the IP address of master node running on host-only vboxnet0 network. This IP was set at post- </li> </ul>

<ul> <li>  As suggested in the directions at the end of the previous output we will allow a non-root user admin level access to the cluster. Take a quick look at the configuration file once it has been copied and the permissions fixed.</ul> </li> 
root@cp:˜# exit

<ul> <li>  Apply the network plugin configuration to your cluster. Remember to copy the file to the current, non-root user directory first  </ul> </li> 

<pre class="notranslate"><code>  # mkdir -p $HOME/.kube;   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config;   sudo chown $(id -u):$(id -g) $HOME/.kube/config </code> </pre>

<h4> To verify the configuration file </h4>
<pre class="notranslate"><code> student@cp:˜$ less .kube/config
1 apiVersion: v1
2 clusters:
3 - cluster:
4 <output_omitted> </code> </pre>

<h4> Install etcdctl-client package. <a href="https://etcd.io/"> etcd is a distributed key/value store </a>  </h4>
<pre class="notranslate"><code>  root@master:~# sudo apt-get install etcd-client -y </code> </pre>

<ul> <li> Integrating Kubernetes and Mesos via the CNI Plugin , it is used for POD to POD network communication. </ul> </li>
  <h4> nstalling the Weave Net CNI plugin <a href="cloud.weave.works/k8s/net?k8s-version=$" </a> weave setup </h4>
  <h4> Weave Net can be installed onto your CNI-enabled Kubernetes cluster with a single command: </h4>

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

<ul> <li> Join the nodes from worker node-1</ul> </li> 
<pre class="notranslate"><code> root@workernode-1# kubeadm join csk-head:6443 --token ha48pt.h9x1xtjqnk9vydkr   --discovery-token-ca-cert-hash sha256:3aa91413e025845fde7027ba3b21e10f8f382fa9856f3caaf6610b618735da27  </code> </pre>

<ul> <li>  Join the nodes from worker node-2 </ul> </li> 
<pre class="notranslate"><code> root@workernode-12# kubeadm join csk-head:6443 --token ha48pt.h9x1xtjqnk9vydkr   --discovery-token-ca-cert-hash sha256:3aa91413e025845fde7027ba3b21e10f8f382fa9856f3caaf6610b618735da27  </code> </pre>

<pre class="notranslate"><code> root@csk-head:~# kubectl get node
NAME          STATUS   ROLES                  AGE     VERSION
workernode-1   Ready    worker1-node           4h47m   v1.21.1
workernode-2   Ready    worker2-node           4h47m   v1.21.1
MasterNode     Ready    control-plane,master   4h53m   v1.21.1  </code> </pre>
