# CS494<공개소프트웨어> 실습프로젝트 

## 프로젝트 상세
### 프로젝트 목표

 - 오픈소스 프로젝트를 사용해 구현해보고 오픈소프 프로젝트 사용 경험 습득
 - 오픈소스 프로젝트에 실질적인 기여
 - Naver의 OSS(Open Source Software)인 [Arcus](https://naver.github.io/arcus/)와 [nBASE-arc](https://github.com/naver/nbase-arc)를 도입해서 샘플 프로젝트를 구현해보고, 도입의 전/후의 성능을 비교해본다.
	 - **DBMS (MySQL, etc.) vs. Arcus (or nBASE-arc)**
	 - 응답시간, TPS 성능, DBMS 트래픽 등
	 - **HubbleMon**을 통한 모니터링
	 - **NGrinder**를 사용한 스트레스 테스트

### 기간: 2017/05/12-2017/06/15

## 프로젝트 보고

### 진행 환경

  프로젝트는 Windows 10 환경에서 진행되었다. Arcus, nBASE-arc 등을 실험하기 위해 Docker 환경을 구성했다. 이를 통해, DBMS와 서버, 클라이언트를 적은 비용으로 쉽게 분리할 수 있다. MySQL 기반의 DBMS와 Arcus, nBASE-arc 서버 및 클라이언트는 각각 Docker container로 분리되었다. Docker의 network 기능을 통해 이들을 서로 연결했고, 테스트는 이를 기반으로 수행되었다. Docker는 Windows 환경에서 내부적으로 VirtualBox를 설치하고, Linux 가상화를 수행한다. 따라서 프로젝트에서는 Linux, 가상화, 그리고 Docker가 모두 사용되었다고 할 수 있다.

### DBMS 구성: `docker build --tag cs494_db mysql`

Docker의 mysql 이미지를 기반으로, 테스트를 위한 MySQL DBMS를 구성했다. Docker가 설치된 상태에서, `docker pull mysql:latest`를 통해 mysql의 최신 Docker 이미지를 가져올 수 있다. 이 이미지와 `mysql/Dockerfile` 을 통해, 테스트 DBMS를 구성할 수 있다. `mysql/Dockerfile` 은 mysql docker의 기본적인 setting 및 스키마를 초기화하는 과정을 수행한다. 
이 DBMS의 기반 스키마는 오픈소스로 공개되어 있는 [Employees Sample DB](https://github.com/datacharmer/test_db) 를 사용했다.

![Sample DB의 스키마](https://github.com/jh-jeong/cs494_oss_project/blob/master/mysql/docker-entrypoint-initdb.d/images/employees.png)

이 스키마에 대한 정보 및 데이터는 `mysql/docker-entrypoint-initdb.d/` 에 저장되어 있다. 이것은 Dockerfile 상에서 컨테이너를 시작할 때 내부로 옮겨지게 되는데, mysql 컨테이너에서는 이 폴더 내부의 `.sql` 파일을 자동으로 실행한다 ([관련 링크](https://hub.docker.com/r/library/mysql/)). 
결론적으로, `docker build --tag cs494_db mysql` 명령을 통해 Employees DB가 초기화된 DBMS Docker image를 build 할 수 있다. 

### Arcus 환경 구성: `docker build --tag arcus arcus`

DBMS와 구분된, Arcus Docker를 구성했다. ubuntu:latest image를 기반으로, [arcus repository ](https://github.com/naver/arcus) 로부터 이를 build할 수 있었다. Arcus를 build 하는 과정에서, 기존의 [arcus-zookeeper](https://github.com/naver/arcus-zookeeper) 는 jdk-1.9 이상에서 빌드하지 못한다는 사실을 발견했다. 이를 패치함으로써, arcus project에 [contribute](https://github.com/naver/arcus-zookeeper/pull/7) 할 수 있었다. 이후로는 jdk 버전이 높아도 정상적인 build가 가능해졌다. Arcus docker를 구성하는 과정은 `arcus/Dockerfile` 를 통해 스크립트화 했다. 

### nGrinder 환경 구성

테스팅을 위해, nGrinder 환경을 구성할 필요가 있었다. nGrinder는 naver에서 공개한 오픈소스 스트레스 테스팅 플랫폼이다. 소스코드도 물론 공개되어 있지만, nGrinder 의 경우 특히 [docker image](https://hub.docker.com/r/ngrinder/controller/)도 배포되어 있어 쉽게 환경을 구축할 수 있었다. 링크의 instruction을 따라 controller container와 agent container를 쉽게 만들 수 있다. 
```
# Run an nGrinder controller
docker pull ngrinder/controller:latest
docker run -d -v ./ngrinder-controller:/opt/ngrinder-controller -p 80:80 -p 16001:16001 -p 12000-12009:12000-12009 ngrinder/controller

# Run an nGrinder agent
docker pull ngrinder/agent:latest
docker run -v ./ngrinder-agent:/opt/ngrinder-agent -d ngrinder/agent ctrl_ip:ctrl_web_port
```

### Docker network 설정

위의 instruction은 각각 잘 동작하지만, 테스팅을 위해 각 컨테이너 간의 communication이 이루어져야 하는 경우 문제가 발생한다. 컨테이너 간 연결을 위해, docker에서는 `--link` 옵션이나 `network` 기능을 제공한다. `--link` 옵션은 추후에 사라질 예정이므로, 여기서는 `network` 기능을 통해 컨테이너 간 연결 환경을 구축했다.  일단 네트워크를 구성하게 되면, 각 컨테이너는 컨테이너의 이름을 통해 다른 컨테이너로 연결할 수 있다.  실제 구성은 아래와 같다. 한 가지 참고사항으로서, nGrinder-controller 의 경우 local browser 와의 연결을 용이하게 하기 위해 추가적으로 port forwarding 설정도 사용했다.  

```
# Create a new network
docker network create cs494-network

# DBMS
docker run -d --name db --network cs494-network cs494_db

# Arcus memcached
docker run -dit --name arcus --network cs494-network arcus

# nGrinder Controller 
docker run -d --name ng_ctrl --network cs494-network -v ./ngrinder-controller:/opt/ngrinder-controller -p 80:80 -p 16001:16001 -p 12000-12009:12000-12009 ngrinder/controller

# nGrinder Agent
docker run -d --name ng_agent --network cs494-network -v ./ngrinder-agent:/opt/ngrinder-agent ngrinder/agent ng_ctrl:80
``` 
 
이렇게 구성된 네트워크에, 실제로 테스팅을 진행할 웹 서버용 컨테이너를 새로 추가했다. 이 서버의 목적은 1) mysql을 direct 하게 가져오는 것과 2) arcus를 사용하는 것의 차이를 알아보기 위함이다. 각 경우 마다 다른 서버 컨테이너를 사용해서 동시에 테스팅 하는 것도 가능하지만,  하나의 로칼 서버 리소스가 공유된다는 점이 동시에 테스팅을 진행하는 환경에서 실험의 주요 오차 요인이 될 가능성이 있다고 판단했다. 따라서 각각의 경우를 따로 실험하기로 결정했고, 그에 따라 웹 서버 역시 하나로 충분하게 되었다. 아래는 결과적인 컨테이너 네트워크를 도식화 한 것이다. 

![Testing network 구성](https://github.com/jh-jeong/cs494_oss_project/blob/master/network.png)

#### Web server 구성

위의 도식에서 확인할 수 있듯, web server는 nGrinder 와 db 서버를 이어주는 역할을 한다. nGrinder 에서 HTTP request 를 사용하기 때문에, web server의 형태로 구현해야 했다. 이 서버의 경우 이전에 동일한 프로젝트를 수행했던 [Github repository](https://github.com/ducky-hong/cs494) 의 ruby + sinatra + thin base 웹서버를 기반으로 본 프로젝트에 맞게 구현되었다. 이렇게 한 이유는, 1) ruby 기반으로 구현할 시 프로젝트에 필요한 기능을 매우 빠르게 구현할 수 있고, 2) 위 Repository 에서 이 기능을 간단한 형태로 구현해 두었기 때문이다. 본 프로젝트에서는 추가적으로, 구성을 더욱 단순화 하기 위해 ruby + sinatra 까지의 구성 과정을 pull 가능한 docker image로 대체했고, web server 를 구성하는 과정을 `web/Dockerfile` 을 통해 자동화했다. 
```
# Build a web server.
docker pull erikap/ruby-sinatra:latest
docker build --tag cs494_web web

# Run the web server.
# Be aware that the container 'web' should be inside the network 'cs494-network',
# which should be defined before it.
docker run -dit --network cs494-network --name web cs494_web
```

`web` container 는 2개의 GET API를 가진다.

 - `GET /mysql`: mysql db 서버에서 직접 data를 query 해서 가져온다.
 - `GET /arcus`: arcus 서버에 data가 있을 시 그것을 가져온다. data가 없을 경우, mysql 서버에서 data를 가져온 뒤 arcus 서버에 등록한다.

각 API는 위에서 정의한 Employees database 에서 10000개의 일정한 employee data를 query한다. 매 query 마다 동일한 data를 얻기 때문에, arcus의 경우 data 전체를 memcached에 등록하고 사용한다.

이로서 testing을 위한 network 구성이 완료되었다. nGrinder는 HTTP request를 보내는 script를 작성할 수 있도록 지원하고, 이것을 agent로 보내 testing을 수행한다. 그리고 web server는 그런 HTTP request를 받아, mysql server나 arcus server와 통신하며 이를 처리할 수 있다. 이제는 실제로 nGrinder를 통해 그러한 script를 작성하여 mysql server를 바로 사용할 때와 arcus server를 통할 때의 성능 차이를 비교할 수 있다. 
