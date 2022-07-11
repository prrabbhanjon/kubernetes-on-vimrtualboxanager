#!/bin/bash

echo -e "\n#############################"
echo      "Set OS - Ubuntu - kubernates "
echo      "#############################"

echo "swap prechecks"
cat /etc/fstab

swapon --show

systemctl --type swap
echo "swap off"

set -x
swapoff /swapfile

echo "disable all swaps from /proc/swaps"
swapoff -a

echo "Permanently Disable Swap"
sed -i '/\/swapfile/s/^/#/' /etc/fstab

echo "swap disabled"
cat /etc/fstab

free -h

echo "Become root and update and upgrade the system. You may be asked a few questions. Allow restarts and keep the local version currently installed. Which would be a yes then a "


apt-get update && apt-get upgrade -y

echo "Install a text editor like nano, vim, or emacs. Any will do, the labs use a popular option, vim"

apt-get install -y vim

echo "using Docker only docker is installing.."
apt-get install -y docker.io
echo "Update the apt package index and install packages needed to use the Kubernetes apt repository:"
sudo apt-get update
echo "Download the Google Cloud public signing key:"
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "Add the Kubernetes apt repository:"
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
echo "Update apt package index, install kubelet, kubeadm and kubectl, and pin their version:"
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
