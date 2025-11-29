#!/bin/bash

# 마스터 노드에서 생성된 조인 명령어 실행
sudo su rocky
scp -o StrictHostKeyChecking=no -i /home/rocky/.ssh/id_rsa rocky@192.168.56.20:/home/rocky/join-command.sh /home/rocky/
chmod +x /home/rocky/join-command.sh
sudo su
/home/rocky/join-command.sh