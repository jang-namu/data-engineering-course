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

 SSH 키 복사 함수
copy_ssh_key() {
  local user=$1
  local host=$2
  echo "${user} to ${user}@${host}"
  su -c "ssh-copy-id -i /home/${user}/.ssh/id_rsa.pub ${user}@${host}" ${user}
}

# docker volume 부착 시, root:root (user:group)으로 부착되어서 dfs 디렉토리 내에 name, data 등 디렉토리를 생성하지 못하는 문제 해결
chown -R hdfs:hadoop /usr/local/hadoop/data
chmod -R 770 /usr/local/hadoop/data
echo "Starting SSH service"
service ssh start

echo "Setting up SSH keys for hdfs user"
setup_ssh hdfs
echo "Setting up SSH keys for yarn user"
setup_ssh yarn



echo "Attempting initial SSH session"
su -c "ssh -o StrictHostKeyChecking=no localhost 'exit'" hdfs
su -c "ssh -o StrictHostKeyChecking=no localhost 'exit'" yarn

## 노드 호스트 이름 배열
#nodes=(master slave1 slave2)
#for target in "${nodes[@]}"; do
#  if [ "$target" != "master" ]; then
#    su -c "ssh -o StrictHostKeyChecking=no ${target} 'exit'" hdfs
#    su -c "ssh -o StrictHostKeyChecking=no ${target} 'exit'" yarn
#  fi
#done
#
## SSH 키 복사 (마스터 노드에서 슬레이브 노드로)
#for target in "${nodes[@]}"; do
#  if [ "$target" != "master" ]; then
#    copy_ssh_key hdfs $target
#    copy_ssh_key yarn $target
#  fi
#done

export HADOOP_HOME=/usr/local/hadoop && export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop && export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin && export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 && export HADOOP_VERSION=3.4.0 &&

# 필요한 초기화 작업 수행
echo "Performing Hadoop initialization tasks"

if [ ! -d /usr/local/hadoop/data/name ]; then
  # hdfs 유저로 전환하여 namenode 포맷
  echo "Formatting namenode as hdfs user"
  su -c "$HADOOP_HOME/bin/hdfs namenode -format" hdfs
fi

echo "Starting HDFS daemons as hdfs user"
su -c "export PDSH_RCMD_TYPE=ssh && export HADOOP_HOME=/usr/local/hadoop && export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop && export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin && export JAVA_HOME=$JAVA_HOME && export HADOOP_VERSION=3.4.0 && $HADOOP_HOME/sbin/start-dfs.sh" hdfs

echo "Setting permissions for Hadoop logs"
chmod -R 770 $HADOOP_HOME/logs

echo "Starting YARN daemons as yarn user"
su -c "export PDSH_RCMD_TYPE=ssh && export HADOOP_HOME=/usr/local/hadoop && export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop && export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin && export JAVA_HOME=$JAVA_HOME && export HADOOP_VERSION=3.4.0 && $HADOOP_HOME/sbin/start-yarn.sh" yarn

echo "Create direcotry /user"
su -c "$HADOOP_HOME/bin/hadoop fs -mkdir /user" hdfs

echo "Create direcotry /user/root"
su -c "$HADOOP_HOME/bin/hadoop fs -mkdir /user/root" hdfs

echo "Change owner /user/root root->hdfs"
su -c "$HADOOP_HOME/bin/hadoop fs -chown root /user/root" hdfs

# 포그라운드 프로세스를 유지하기 위한 임시 명령 (예시)
echo "Keeping a foreground process to maintain the script running"
tail -f /dev/null