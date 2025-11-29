#!/bin/bash

set -e  # 에러 발생 시 스크립트 중단

# kubeadm으로 마스터 노드 초기화
# Rocky Linux 8의 커널 4.18은 공식적으로 지원되지 않으므로 SystemVerification 에러 무시
sudo kubeadm init \
    --apiserver-advertise-address=192.168.56.20 \
    --pod-network-cidr=10.244.0.0/16 \
    --ignore-preflight-errors=SystemVerification

# kubeadm init 성공 확인
if [ ! -f /etc/kubernetes/admin.conf ]; then
    echo "Error: kubeadm init failed - admin.conf not found"
    exit 1
fi

# 일반 사용자도 kubectl을 사용할 수 있게 설정
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# vagrant 사용자를 위한 설정
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config

# rocky 사용자를 위한 설정
mkdir -p /home/rocky/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/rocky/.kube/config
sudo chown rocky:rocky /home/rocky/.kube/config

# Calico 네트워크 플러그인 설치
sudo kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Calico가 준비될 때까지 대기
echo "Waiting for Calico to be ready..."
sudo kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n kube-system --timeout=300s || true

# master에서 pod 생성할 수 있도록 설정
sudo kubectl taint nodes k8s-master node-role.kubernetes.io/control-plane- --allow-missing-template-keys || true

# dashboard 설치
sudo kubectl apply -f /vagrant/dashboard/dashboard.yaml

# metrics-server 설치
sudo kubectl apply -f /vagrant/metrics/metrics-server.yaml

# 워커 노드 조인을 위한 토큰 생성 및 저장
sudo kubeadm token create --print-join-command > /home/rocky/join-command.sh
chmod +x /home/rocky/join-command.sh