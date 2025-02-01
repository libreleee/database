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

## High Availability Compare (mysql 고가용성 솔루션)
| 항목 | Oracle|MySQL MariaDB | MySQL | MariaDB |
|-------|-------|------|------|------|
| HA      |Data Guard       | Replication MHA,MMM,galera cluster   ![image](https://github.com/libreleee/database/assets/117779419/15f2a68e-0deb-4f72-981b-132255a9e9b5) | **cluster-ndb**  Rocky9.5,mysql-8.0.41 ndb-8.0.41  | https://mariadb.com/kb/en/ndb-in-mariadb/ NDB(MySQL 클러스터)는 MariaDB 10.0 까지 기본적으로 비활성화되었으며 , MariaDB 10.1 에서 완전히 제거되었습니다.<br>적극적으로 개발되고 있는 대안에 대해서는 Galera Cluster를 참조하세요.<br> 아쉽지만 cluster ndb는 mysql을 당분간 사용<br> **성능과 확장성 측면에서는 NDB가 우세인 상황, 관리즉면은 조금 부담** |
||||
| Switch Over Connection       |TAF(RAC)     | MaxScale or ProxySQL,    | ndb LoadBalancer |

## mysql galera cluster, use percona-xtradb-cluster 8.0
참고 사이트 https://docs.percona.com/percona-xtradb-cluster/8.0/quickstart-overview.html

* Docker를 이용한 테스트<br>

**1. Create a pxc-docker-test/config directory. 작업할 디렉토리를 만든다**
<pre>
<code>
   mkdir pxc-docker-test
   cd pxc-doecker-test
   mkdir config
</code>
</pre>

**2. Create a custom.cnf file . mysql configuration파일 만든다** <br>
    
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

**3. Create a cert directory and generate self-signed SSL certificates on the host node 인증 관련 Directory 생성과 인증관련 파일 생성**
<pre><code>
cd  ..   -> pxc-docker-test
mkdir -m 777 -p cert
docker run --name pxc-cert --rm -v ./cert:/cert
percona/percona-xtradb-cluster:8.0 mysql_ssl_rsa_setup -d /cert
</code>
</pre>

현재 dir tree


**4. Create a Docker network**
<pre>
 <code>
docker network create pxc-network
 </code>
</pre>

현재 dir tree
<pre>
<code>
 pxc-docker-test
    ├── cert
    │   ├── ca-key.pem
    │   ├── ca.pem
    │   ├── client-cert.pem
    │   ├── client-key.pem
    │   ├── private_key.pem
    │   ├── public_key.pem
    │   ├── server-cert.pem
    │   └── server-key.pem
    └── config
        └── custom.cnf 
</code>
</pre>
**5. Bootstrap the cluster (create the first node) 클러스터 부트스트랩, node1** <br>
pxc-docker-test$  실행위치
<pre>
<code>

docker run -d \
-e MYSQL_ROOT_PASSWORD=test1234# \
-e CLUSTER_NAME=pxc-cluster1 \
--name=pxc-node1 \
--net=pxc-network \
-v ./cert:/cert \
-v ./config:/etc/percona-xtradb-cluster.conf.d \
percona/percona-xtradb-cluster:8.0     
</code></pre>

**6. Join the second node, 2 번쩨 노드 join**
<pre>
<code>
docker run -d \
-e MYSQL_ROOT_PASSWORD=test1234# \
-e CLUSTER_NAME=pxc-cluster1 \
-e CLUSTER_JOIN=pxc-node1 \
--name=pxc-node2 \
--net=pxc-network \
-v ./cert:/cert \
-v ./config:/etc/percona-xtradb-cluster.conf.d \
percona/percona-xtradb-cluster:8.0
</code>
</pre>

**7. Join the third node, 3 번째 노드 join**
<pre>
<code>
docker run -d \
-e MYSQL_ROOT_PASSWORD=test1234# \
-e CLUSTER_NAME=pxc-cluster1 \
-e CLUSTER_JOIN=pxc-node1 \
--name=pxc-node3 \
--net=pxc-network \
-v ./cert:/cert \
-v ./config:/etc/percona-xtradb-cluster.conf.d \
percona/percona-xtradb-cluster:8.0
</code>
</pre>

**8. Check Cluster, Access the MySQL client. For example, on the first node, 클러스터 확인, node1**
<pre>
<code>
sudo docker exec -it pxc-node1 mysql -uroot -ptest1234#

mysql> show status like 'wsrep_cluster_size%';
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 3     |
+--------------------+-------+
1 row in set (0.03 sec)
</code>
</pre>
!!! 여기에서 값이 1이면 클러스터 설정이 제대로 안된상태

**9. Verify replication, 클러스터 replication 확인**<br>
 1) Create a new database on the second node, node2 에서 create database
<pre>
<code>
mysql> CREATE DATABASE percona;
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| percona            |
| performance_schema |
| sys                |
+--------------------+
5 rows in set (0.07 sec)

mysql> use percona;
Database changed
</code>
</pre>

 2) Create a table on the third node, Create 테이블은 node3
<pre>
<code>
mysql> CREATE TABLE example (node_id INT PRIMARY KEY, node_name VARCHAR(30));
</code>
</pre>

 3) Insert records on the first node, Insert 데이터는 node1
<pre>
<code>
mysql> INSERT INTO percona.example VALUES (1, 'percona1');
</code>
</pre>

 4) Retrieve rows from that table on the second node, 조회는 node2
<pre>
<code>
mysql> SELECT * FROM percona.example;
+---------+-----------+
| node_id | node_name |
+---------+-----------+
|       1 | percona1  |
+---------+-----------+
1 row in set (0.00 sec)
</code>
</pre>
