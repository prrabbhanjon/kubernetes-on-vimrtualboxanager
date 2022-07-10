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

# Exercise 3.1: Install Kubernetes - PC/Mac

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
<ul> <li>The main choices for a container environment are Docker r and cri-o. We suggest Docker for class, as cri-o is not yet
the default when building the cluster with kubeadm on Ubuntu.
The cri-o engine is the default in Red Hat products and is being implemented by others. Installing Docker is a single
command. At the moment it takes several steps to install and configure crio. Also the cluster node name may be set
differently depending on what you put in the cluster configuration files. </li> </ul> 
<h4> very important: if you want extra challenge use cri-o. Otherwise install Docker </h4>
Please note, install Docker OR cri-o. If both are installed the kubeadm init process search pattern will use Docker. Also
be aware that if you choose to use cri-o you may find encounter different output than shown in the book.
(a) If using Docker:
root@cp:˜# apt-get install -y docker.i
