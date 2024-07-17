#!/usr/bin/env bash

# SSH 키 생성 및 설정 함수
setup_ssh() {
  local user=$1
  su - $user -c "
  ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
  mkdir -p ~/.ssh
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
  chmod 0600 ~/.ssh/authorized_keys
  "
}

# docker volume 부착 시, root:root (user:group)으로 부착되어서 dfs 디렉토리 내에 name, data 등 디렉토리를 생성하지 못하는 문제 해결
chown -R hdfs:hadoop /tmp/hadoop-hdfs/dfs
chmod -R 770 /tmp/hadoop-hdfs/dfs
echo "Starting SSH service"
service ssh start

echo "Setting up SSH keys for hdfs user"
setup_ssh hdfs
echo "Setting up SSH keys for yarn user"
setup_ssh yarn

echo "Attempting initial SSH session"
#su - hdfs -c "ssh -o StrictHostKeyChecking=no localhost"
su -c "ssh -o StrictHostKeyChecking=no localhost 'exit'" hdfs
#su - yarn -c "ssh -o StrictHostKeyChecking=no localhost"
su -c "ssh -o StrictHostKeyChecking=no localhost 'exit'" yarn

# 필요한 초기화 작업 수행
echo "Performing Hadoop initialization tasks"
export HADOOP_VERSION=3.4.0

if [ ! -d /tmp/hadoop-hdfs/dfs/name ]; then
  # hdfs 유저로 전환하여 namenode 포맷
  echo "Formatting namenode as hdfs user"
  su -c "/opt/hadoop-$HADOOP_VERSION/bin/hdfs namenode -format" hdfs
fi

echo "Starting HDFS daemons as hdfs user"
su -c "export PDSH_RCMD_TYPE=ssh && /opt/hadoop-$HADOOP_VERSION/sbin/start-dfs.sh" hdfs

echo "Setting permissions for Hadoop logs"
chmod -R 770 /opt/hadoop-$HADOOP_VERSION/logs

echo "Starting YARN daemons as yarn user"
su -c "export PDSH_RCMD_TYPE=ssh && /opt/hadoop-$HADOOP_VERSION/sbin/start-yarn.sh" yarn

echo "Create direcotry /user"
su -c "/opt/hadoop-$HADOOP_VERSION/bin/hadoop fs -mkdir /user" hdfs

echo "Create direcotry /user/root"
su -c "/opt/hadoop-$HADOOP_VERSION/bin/hadoop fs -mkdir /user/root" hdfs

echo "Change owner /user/root root->hdfs"
su -c "/opt/hadoop-$HADOOP_VERSION/bin/hadoop fs -chown root /user/root" hdfs

# 포그라운드 프로세스를 유지하기 위한 임시 명령 (예시)
echo "Keeping a foreground process to maintain the script running"
tail -f /dev/null