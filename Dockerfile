FROM ubuntu:bionic

ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-amd64/jre
ENV HADOOP_HOME /opt/hadoop
ENV HADOOP_CONF_DIR /opt/hadoop/etc/hadoop
ENV SPARK_HOME /opt/spark
ENV HIVE_HOME /opt/hive
ENV PATH="${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${HIVE_HOME}/bin:${PATH}"
ENV PYTHONPATH="${SPARK_HOME}/python:${SPARK_HOME}/python/lib/py4j-0.10.7-src.zip:${PYTHONPATH}"
ENV CLASSPATH="{$CLASSPATH}:${HADOOP_HOME}/lib/*:${HIVE_HOME}/lib/*"
ENV HADOOP_VERSION 2.7.0
# ENV PYSPARK_DRIVER_PYTHON=jupyter
# ENV PYSPARK_DRIVER_PYTHON_OPTS='notebook'
ENV PYSPARK_PYTHON=python3

RUN apt-get update && \
    apt-get install -y wget nano openjdk-8-jdk ssh openssh-server
RUN apt update && apt install -y python3 python3-pip python3-dev build-essential libssl-dev libffi-dev libpq-dev

COPY /confs/requirements.req /
RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.req
RUN pip3 install dask[bag] --upgrade
RUN pip3 install --upgrade toree
RUN python3 -m bash_kernel.install

RUN wget -P /tmp/ https://archive.apache.org/dist/hadoop/common/hadoop-2.7.0/hadoop-2.7.0.tar.gz
RUN tar xvf /tmp/hadoop-2.7.0.tar.gz -C /tmp && \
	mv /tmp/hadoop-2.7.0 ${HADOOP_HOME}

RUN wget -P /tmp/ https://archive.apache.org/dist/spark/spark-2.4.8/spark-2.4.8-bin-hadoop2.7.tgz
RUN tar xvf /tmp/spark-2.4.8-bin-hadoop2.7.tgz -C /tmp && \
    mv /tmp/spark-2.4.8-bin-hadoop2.7 ${SPARK_HOME}

RUN wget -P /tmp/ https://dlcdn.apache.org/hive/hive-2.3.9/apache-hive-2.3.9-bin.tar.gz
RUN tar xvf /tmp/apache-hive-2.3.9-bin.tar.gz -C /tmp && \
	mv /tmp/apache-hive-2.3.9-bin ${HIVE_HOME}

RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
	cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
	chmod 600 ~/.ssh/authorized_keys
COPY /confs/config /root/.ssh
RUN chmod 600 /root/.ssh/config

COPY /confs/*.xml /opt/hadoop/etc/hadoop/
COPY /confs/slaves /opt/hadoop/etc/hadoop/
COPY /script_files/bootstrap.sh /
COPY /confs/spark-defaults.conf ${SPARK_HOME}/conf
COPY /confs/hive-site.xml ${HIVE_HOME}/conf

RUN jupyter toree install --spark_home=${SPARK_HOME}
RUN echo "export JAVA_HOME=${JAVA_HOME}" >> /etc/environment

RUN mkdir lab

ENTRYPOINT ["/bin/bash", "bootstrap.sh"]
