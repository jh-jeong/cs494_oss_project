FROM ubuntu:latest
MAINTAINER Jongheon Jeong <jongheonj@kaist.ac.kr>

RUN apt-get update
RUN apt-get install -y wget vim git apt-utils netcat
RUN apt-get -o Dpkg::Options::="--force-overwrite" install -y openjdk-8-jdk
RUN cd /opt/; wget http://apache.tt.co.kr//ant/binaries/apache-ant-1.10.1-bin.tar.gz
RUN cd /opt/; tar -xzf apache-ant-1.10.1-bin.tar.gz
RUN ln -s /opt/apache-ant-1.10.1 /opt/ant

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV ANT_HOME=/opt/ant
ENV PATH=$JAVA_HOME/bin:$ANT_HOME/bin:$PATH

RUN apt-get install -y build-essential autoconf automake libtool libcppunit-dev python-setuptools python-dev

EXPOSE 2181
EXPOSE 11211
EXPOSE 11212

RUN useradd -m -s /bin/bash jongheonj
USER jongheonj

RUN cd /home/jongheonj/; git clone https://github.com/naver/arcus.git
RUN cd /home/jongheonj/arcus/scripts; ./build.sh
