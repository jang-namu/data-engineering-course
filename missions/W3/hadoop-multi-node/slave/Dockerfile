FROM --platform=linux/amd64 ubuntu:22.04

ENV PDSH_RCMD_TYPE=ssh
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV HADOOP_VERSION=3.4.0
ENV HDFS_NAMENODE_USER=hdfs
ENV HDFS_DATANODE_USER=hdfs
ENV HDFS_SECONDARYNAMENODE_USER=hdfs
ENV YARN_RESOURCEMANAGER_USER=yarn
ENV YARN_NODEMANAGER_USER=yarn

RUN apt update && \
    apt install -y openjdk-8-jdk ssh pdsh wget

# Download and extract Hadoop to /opt
RUN wget https://dlcdn.apache.org/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz -P /opt && \
    tar -xzvf /opt/hadoop-$HADOOP_VERSION.tar.gz -C /opt && \
    mv /opt/hadoop-$HADOOP_VERSION /usr/local/hadoop && \
    rm /opt/hadoop-$HADOOP_VERSION.tar.gz

WORKDIR /opt/hadoop-$HADOOP_VERSION

COPY core-site.xml etc/hadoop/core-site.xml
COPY hdfs-site.xml etc/hadoop/hdfs-site.xml
COPY mapred-site.xml etc/hadoop/mapred-site.xml
COPY yarn-site.xml etc/hadoop/yarn-site.xml

# 사용자 및 그룹 생성 및 권한 설정
RUN groupadd hadoop && \
    useradd -m -g hadoop hdfs && \
    useradd -m -g hadoop yarn && \
    mkdir /opt/hadoop-$HADOOP_VERSION/logs && \
    chown -R :hadoop /opt/hadoop-$HADOOP_VERSION/ && \
    chmod -R 770 /opt/hadoop-$HADOOP_VERSION/



COPY start.sh start.sh
RUN chmod +x start.sh


Run echo 'export HADOOP_HOME=/usr/local/hadoop' >> /root/.bashrc && \
    echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> /root/.bashrc && \
    echo 'export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin' >> /root/.bashrc && \
    echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> /root/.bashrc && \
    source /root/.bashrc

RUN touch $HADOOP_CONF_DIR/masters && \
    echo -e 'master\n' >> $HADOOP_CONF_DIR/masters

RUN touch $HADOOP_CONF_DIR/slaves && \
    echo -e 'slave1\nslave2\n' >> $HADOOP_CONF_DIR/slaves

EXPOSE 9870 8088 9864 8042

ENTRYPOINT ["./start.sh"]
