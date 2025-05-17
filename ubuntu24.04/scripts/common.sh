#!/bin/bash

# 비대화형 설치를 위한 환경변수 설정 (우분투도 Debian 기반이기 때문에 사용)
export DEBIAN_FRONTEND=noninteractive

# grub 업데이트 관련 설정 (사전 구성)
echo 'grub-pc grub-pc/install_devices multiselect /dev/sda' | debconf-set-selections
echo 'grub-pc grub-pc/install_devices_disks_changed multiselect /dev/sda' | debconf-set-selections

# 시스템 업데이트
## update: 원격 저장소에서 패키지 목록을 받아와 최신화
## upgrade: 최신화된 패키지 목록을 기반으로 설치된 패키지를 업그레이드
apt-get update -y
apt-get upgrade -y

# ubuntu 유저 생성
useradd -m -s /bin/bash ubuntu
usermod -aG sudo ubuntu
passwd -d ubuntu

# SSH 디렉토리 생성
mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh
cat /vagrant/shared/k8s-test > /home/ubuntu/.ssh/id_rsa
chmod 600 /home/ubuntu/.ssh/id_rsa
cat /vagrant/shared/k8s-test.pub > /home/ubuntu/.ssh/authorized_keys
chmod 600 /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh

# 필요한 패키지 설치
## apt-transport-https: HTTPS를 통한 패키지 설치를 위한 패키지 (k8s 저장소는 보안을 위해 https 사용하기 때문)
## ca-certificates: 신뢰할 수 있는 CA의 인증서 모음 (https 통신 시 필요)
## curl: HTTP 요청을 보내는 데 사용되는 패키지
## gnupg: 공개키 암호를 이용하여 파일을 암/복호화 or 전자서명하는 패키지 (k8s 저장소는 보안을 위해 공개키 암호를 사용하기 때문)
## lsb-release: 리눅스 배포판 정보를 제공하는 패키지
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# 방화벽 비활성화
ufw disable

# 스왑 비활성화
swapoff -a
sed -i '/swap/d' /etc/fstab

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
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y containerd.io

# containerd 설정
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
# pause 이미지 버전 업데이트 (3.8 → 3.10)
sed -i 's|registry.k8s.io/pause:3.registry.k8s.io/pause:3.10|g' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# Kubernetes 저장소 추가
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Kubernetes 패키지 설치
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl