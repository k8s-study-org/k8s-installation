#!/bin/bash

sleep 30  # 마스터 노드가 초기화를 완료할 때까지 대기

# 마스터 노드에서 생성된 조인 명령어 실행
sudo su ubuntu
scp -o StrictHostKeyChecking=no -i /home/ubuntu/.ssh/id_rsa ubuntu@192.168.56.10:/home/ubuntu/join-command.sh /home/ubuntu/
chmod +x /home/ubuntu/join-command.sh
sudo su
/home/ubuntu/join-command.sh