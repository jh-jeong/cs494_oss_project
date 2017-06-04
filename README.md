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

이 DBMS의 기반 스키마는 오픈소스로 공개되어 있는 [Employees Sample DB](https://github.com/datacharmer/test_db) 를 사용했다. 이 스키마에 대한 정보 및 데이터는 `mysql/docker-entrypoint-initdb.d/` 에 저장되어 있다. 이것은 Dockerfile 상에서 컨테이너를 시작할 때 내부로 옮겨지게 되는데, mysql 컨테이너에서는 이 폴더 내부의 `.sql` 파일을 자동으로 초기화한다 ([관련 링크](https://hub.docker.com/r/library/mysql/)). 
결론적으로, `docker build --tag cs494_db mysql` 명령을 통해 Employees DB가 초기화된, 프로젝트를 위한 DBMS Docker image를 build 할 수 있다. 


