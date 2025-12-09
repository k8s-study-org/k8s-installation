#!/bin/bash

echo '======== Disk 확장 설정 ========'
yum install -y cloud-utils-growpart
growpart /dev/sda 4
xfs_growfs /dev/sda4


echo '======== 도커 설치 ========'
yum install -y docker-ce-3:23.0.6-1.el8 docker-ce-cli-1:23.0.6-1.el8 containerd.io-1.6.21-3.1.el8
systemctl daemon-reload
systemctl enable --now docker

echo '======== OpenJDK 설치  ========'
# yum list --showduplicates java-17-openjdk
yum install -y java-17-openjdk

echo '======== Gradle 설치  ========'
yum -y install wget unzip
wget https://services.gradle.org/distributions/gradle-7.6.1-bin.zip -P ~/
unzip -d /opt/gradle ~/gradle-*.zip
cat <<EOF |tee /etc/profile.d/gradle.sh
export GRADLE_HOME=/opt/gradle/gradle-7.6.1
export PATH=/opt/gradle/gradle-7.6.1/bin:${PATH}
EOF
chmod +x /etc/profile.d/gradle.sh
source /etc/profile.d/gradle.sh

echo '======== Git 설치  ========'
# 기존엔 git-2.43.0-1.el8 버전을 Fix하였으나 Repository에 최신 버전만 업로드 됨으로 수정
yum install -y git

echo '======== Jenkins 설치  ========'
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
yum install -y jenkins-2.528.2
systemctl enable jenkins
systemctl start jenkins