# qWindTDB
kdb+/q interface for Wind TDB

# ����

   ��kdb+/q�е���wind TDB�ӿڣ�**Wind�շѽӿڣ���Ҫ����ӿ��˺�**���������ݡ������߳�������ά�������Կ��á�����
   
   �Ƽ�FlyingOE������q_Wind���Wind TDB�ӿڣ�<https://github.com/FlyingOE/q_Wind>

# ����

q/hd_windtdb.q

q/w32/qwindtdb.dll

q/w32/TDBAPI.dll

q/w32/msvcp140.dll

q/w32/msvcr140.dll

msvcr100.dll

msvcp100.dll

# �÷�

1. ���ر��ű��ļ��� \l hd_windtdb.q

2. ����tdb������: start[`ip;`port;`user;`password] 

3. ����tick���ݲ����浽(fe)\hdb\���ݿ⣺tdb2cstaq ...   tdb2cftaq  ...

4. �Ͽ����ӣ�stop[]��ʹ�ý�����Ҫ�Ͽ����ӣ�����

5. �����װ������hd_windtdb.q���磺
```q
\l hd_windtdb.q
start[`ip;`port;`user;`password];
tdb2csbar5m[(2017.01.01;.z.D)] ;  
tdb2csbar0 [(2017.01.01;.z.D)] ;  
tdb2cstaq  [(2017.01.01;.z.D)] ; 
stop[];
.Q.chk[hdbpath[]];
```


