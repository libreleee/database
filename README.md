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
  
 

![swim-real](https://user-images.githubusercontent.com/117779419/206681473-03b6a53c-cd2b-4f88-98f6-0bc064122145.PNG)
