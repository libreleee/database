# database
Database

## Oracle High Availability System


1. Make a backup of the primary datafiles (or access a previous backup) and create the standby control file. \
2.Transfer the standby datafiles and control file to the standby site. \
3.Configure Net8 so that you can connect to the standby service name. \
4.Configure the primary and standby initialization parameter files. \
5.Initiate automatic archiving on the primary site. \
6.Start the standby instance without mounting it. \


![oracle-standby](https://user-images.githubusercontent.com/117779419/206435109-e87f026e-a7c3-4483-a77c-73e145597bfa.PNG)


## BackUp and Recovery 백업 및 복원 - 실제로 발생 되었던 상황

1. 프로젝트 마지막 단계 서비스 오픈 
2. 서비스오픈 1:30분 경과 
3. 서비스오픈 1:45분 경과 - SI업체 DBA가 실제 운영 Database를 개발 DB로 착각, 운영 중인 전체 DB를 Drop Database 명령 실행 
4. 서비스오픈 2:00분 경과 - 총괄 DBA에게 장애접수   
5. 서비스오픈 2:00분 경과 - 정보시스템 장애발생
6. 서비스오픈 2:15분 경과 - Storage Snapshot 장애상황 복제 되어 사용불가, Standby DB 복구결정 및 복구시작
7. 서비스오픈 2:45분 경과 - Standby Database Primary DB로 Open
8. 서비스오픈 3:00분 경과 - 정보시스템 정상오픈 

| 항목 | 변경전|변경후  |
|-------|-------|------|
|Storage Snapshot 간격 | 1시간    |   3시간   |
|Standby Apply 간격|     3시간     |  5시간    |
|DB Security      | Case by Case|  All    |

 + 역활 : 총괄 DBA, PM 업무 수행
  
 

![swim-real](https://user-images.githubusercontent.com/117779419/206687895-000af29e-03da-4f9b-be7c-d5916c7d5b83.PNG)

Standby Database info Query
```
select database_role, db_unique_name INSTANCE, open_mode, protection_mode, protection_level, switchover_status
FROM v$database;  
```

Last log Applied On Standby Info Query
```
select thread#, Max(sequence#) 
FROM v$archived_log
WHERE  applied = ‘YES’
GROUP  BY thread#;   
```

## High Availability Compare
| 항목 | Oracle|MySQL MariaDB |
|-------|-------|------|
| HA      |Data Guard       | Replication MHA,MMM,galera cluster   ![image](https://github.com/libreleee/database/assets/117779419/15f2a68e-0deb-4f72-981b-132255a9e9b5)
||||
| Switch Over Connection       |TAF(RAC)     | MaxScale or ProxyS   |

## mysql galera cluster, use percona-xtradb-cluster 8.0
참고 사이트 https://docs.percona.com/percona-xtradb-cluster/8.0/quickstart-overview.html

* Docker를 이용한 테스트
1. Create a pxc-docker-test/config directory. 작업할 디렉토리를 만든다
   mkdir pxc-docker-test
   cd pxc-doecker-test
   mkdir config
   
3. Create a custom.cnf file . mysql configuration파일 만든다 <br>
    
<pre><code>
cd config 
vi custom.cnf 
 
[mysqld]
ssl-ca = /cert/ca.pem
ssl-cert = /cert/server-cert.pem
ssl-key = /cert/server-key.pem

[client]
ssl-ca = /cert/ca.pem
ssl-cert = /cert/client-cert.pem
ssl-key = /cert/client-key.pem

[sst]
encrypt = 4
ssl-ca = /cert/ca.pem
ssl-cert = /cert/server-cert.pem
ssl-key = /cert/server-key.pem
</code> 
</pre>

4.Create a cert directory and generate self-signed SSL certificates on the host node 인증 관련 Directory 생성과 인증관련 파일 생성
<pre><code>
cd  ..   -> pxc-docker-test
mkdir -m 777 -p cert
docker run --name pxc-cert --rm -v ./cert:/cert
percona/percona-xtradb-cluster:8.0 mysql_ssl_rsa_setup -d /cert
</code>
</pre>

5.Create a Docker network
<pre>
 <code>
docker network create pxc-network
 </code>
</pre>
