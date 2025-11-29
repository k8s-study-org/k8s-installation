#!/bin/bash

# Kubernetes 버전 설정 (필요시 수정)
## 버전 형식: MAJOR.MINOR.PATCH-RELEASE (예: 1.33.0-0)
## 사용 가능한 버전 확인: yum --showduplicates list kubelet
K8S_VERSION="${K8S_VERSION:-1.33.0-0}"
K8S_MAJOR_VERSION="${K8S_MAJOR_VERSION:-v1.33}"

set -e

# 시스템 업데이트
yum update -y

# 기본 필수 패키지 설치
## yum-utils: yum 유틸리티 패키지
## curl: HTTP 요청을 보내는 데 사용되는 패키지
## git: k8s 오브젝트를 다운받기 위해 설치
## ca-certificates: 신뢰할 수 있는 CA의 인증서 모음 (https 통신 시 필요)
yum install -y yum-utils curl git ca-certificates

# 기본 유저 생성
## Rocky8/RHEL 계열은 wheel 그룹을 사용 (sudo 그룹이 아닌 경우를 대비)
useradd -m -s /bin/bash rocky
usermod -aG wheel rocky
passwd -d rocky

# SSH 디렉토리 생성
mkdir -p /home/rocky/.ssh
chmod 700 /home/rocky/.ssh
cat /vagrant/shared/k8s-test > /home/rocky/.ssh/id_rsa
chmod 600 /home/rocky/.ssh/id_rsa
cat /vagrant/shared/k8s-test.pub > /home/rocky/.ssh/authorized_keys
chmod 600 /home/rocky/.ssh/authorized_keys
chown -R rocky:rocky /home/rocky/.ssh

# timezone 설정
timedatectl set-timezone Asia/Seoul
timedatectl set-ntp true

# SELinux permissive 모드 설정 (Kubernetes 환경에서 권장)
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config

# 방화벽 해제
systemctl stop firewalld && systemctl disable firewalld

# 스왑 비활성화
swapoff -a && sed -i '/ swap / s/^/#/' /etc/fstab

# 브리지 네트워크 설정
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# containerd 설치
## Docker 저장소 추가
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y containerd.io

# containerd 설정
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
# pause 이미지 버전 업데이트 (3.8 → 3.10)
sed -i 's|registry.k8s.io/pause:3.8|registry.k8s.io/pause:3.10|g' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# Kubernetes 저장소 추가
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/${K8S_MAJOR_VERSION}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/${K8S_MAJOR_VERSION}/rpm/repodata/repomd.xml.key
EOF

# Kubernetes 패키지 설치 (특정 버전)
yum install -y kubelet kubeadm kubectl
systemctl enable kubelet

# Kubernetes 패키지 버전 고정 (업데이트 방지)
yum install -y yum-plugin-versionlock
yum versionlock add kubelet kubeadm kubectl