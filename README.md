# qWindTDB
kdb+/q interface for Wind TDB

# 功能

   在kdb+/q中调用wind TDB接口（**Wind收费接口，需要购买接口账号**）下载数据。代码冗长，不再维护，虽仍可用。。。
   
   推荐FlyingOE大侠的q_Wind里的Wind TDB接口：<https://github.com/FlyingOE/q_Wind>

# 依赖

q/hd_windtdb.q

q/w32/qwindtdb.dll

q/w32/TDBAPI.dll

q/w32/msvcp140.dll

q/w32/msvcr140.dll

msvcr100.dll

msvcp100.dll

# 用法

1. 加载本脚本文件： \l hd_windtdb.q

2. 连接tdb服务器: start[`ip;`port;`user;`password] 

3. 下载tick数据并保存到(fe)\hdb\数据库：tdb2cstaq ...   tdb2cftaq  ...

4. 断开连接：stop[]，使用结束后要断开连接！！！

5. 更多封装函数见hd_windtdb.q，如：
```q
\l hd_windtdb.q
start[`ip;`port;`user;`password];
tdb2csbar5m[(2017.01.01;.z.D)] ;  
tdb2csbar0 [(2017.01.01;.z.D)] ;  
tdb2cstaq  [(2017.01.01;.z.D)] ; 
stop[];
.Q.chk[hdbpath[]];
```


