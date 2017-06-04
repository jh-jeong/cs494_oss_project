FROM mysql:latest
MAINTAINER Jongheon Jeong <jongheonj@kaist.ac.kr>

ENV MYSQL_ROOT_PASSWORD jongheonj
ENV MYSQL_DATABASE employees

COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/