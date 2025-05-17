# k8s-installation
## Overview
This project provides an automated tool for building a Kubernetes cluster in a local environment using Vagrant and VirtualBox. It allows you to easily set up a fully functional Kubernetes cluster consisting of one master node and two worker nodes.

## Prerequisites
- VirtualBox
- Vagrant
- Vagrant plugins
```bash
vagrant plugin install vagrant-disksize
vagrant plugin install vagrant-vbguest
```


## Installation Steps
### 1. Clone the repository:
```bash
git clone https://github.com/your-username/k8s-installation.git
cd k8s-installation/<os>
```
### 2. SSH Key Setup (optional)
- SSH keys are already included in the shared directory
- You can replace them with your own SSH keys if needed
### 3. Create the cluster
```bash
vagrant up
```
-  This process may take 10-15 minutes depending on your environment

## Cluster Configuration
| Node | Role | IP Address | OS | SSH Port |
|------|------|------------|----|----|
| k8s-master | Master Node | 192.168.56.10 | Ubuntu 24.04 | 2000 |
| k8s-worker-1 | Worker Node | 192.168.56.11 | Ubuntu 24.04 | 2001 |
| k8s-worker-2 | Worker Node | 192.168.56.12 | Ubuntu 24.04 | 2002 |