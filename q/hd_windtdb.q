//=============================kdb+Wind数据接口=============================
// 功能：在kdb+中调用wind TDB
// 依赖：q/hd_windtdb.q, q/w32/qwindtdb.dll,q/w32/TDBAPI.dll, q/w32/msvcp140.dll, q/w32/msvcr140.dll, msvcr100.dll,msvcp100.dll
// 用法：1. 加载本脚本文件： \l hd_windtdb.q
//       2. 连接tdb服务器: start[`ip;`port;`user;`password] 
//       3. 下载tick数据并保存到(fe)\hdb\数据库：tdb2cstaq ...   tdb2cftaq  ...
//       4. 断开连接：stop[]，使用结束后要断开连接！！！
//==========================================================================
.z.zd:(17;3;0);  
windmktmaps:`SH`SZ`CF`CFE`SHF`DCE`CZC!(`$"SH-2-0";`$"SZ-2-0";`$"CF-2-0";`$"CF-2-0";`$"SHF-1-0";`$"DCE-1-0";`$"CZC-1-0");   //市场(格式:Market-Level-Source(SZ-2-0))
sym2windmkt:{windmktmaps last ` vs x};
mktmaps:`SZ`SH`CF`SHF`DCE`CZC!`SZ`SH`CFE`SHF`DCE`CZC;
/API函数 
.windtdb.apifuncs:`start`stop`getsyms`getbars`gettick`gettick2`gettickAB`getfuturetick`getfuturetick2`getfuturetickAB`gettransaction`getorder`getorderqueue;
$[-11h=type key hsym `$getenv[`qhome],"\\",(string .z.o),"\\qwindtdb.dll";    .windtdb.apifuncs {.windtdb[x] : `qwindtdb 2:(x;y);}' (count .windtdb.apifuncs)#1;   '`qwindtdb.dll_not_exists]; 
/共用表、函数等
shindexmap:`999999.SH`999998.SH`999997.SH`999996.SH`999995.SH`999994.SH`999993.SH`999992.SH`999991.SH`999990.SH`999989.SH`999988.SH`999987.SH`999986.SH`000300.SH!`000001.SH`000002.SH`000003.SH`000004.SH`000005.SH`000006.SH`000007.SH`000008.SH`000010.SH`000011.SH`000012.SH`000013.SH`000016.SH`000015.SH`000300.SH;
/windtdb代码转换为wind代码  tdbsym2sym each `999999.SH`000300.SH`999991.SH`990099.SH`000001.SZ`399001.SZ`600036.SH`IF1306.CF`CU1307.SHF`A1307.DCE`WH307.CZC`Ag999.SGE              CF与wind终端规范不同！！！！！！
tdbsym2sym:{x:upper x;:$[x in key shindexmap; shindexmap[x]; x like "99????.SH";(`$"00",2_string x);  x like "*.CF";(`$(upper string x),"E");   x];};
/平台代码转换为wind代码   sym2tdbsym each `IF1306.CFE`000001.SH`000001.SZ`CU1307.SHF`A1307.DCE`
sym2tdbsym:{:$[x in value shindexmap;:shindexmap?x;  x like "*.CFE";`$-1_(string x);   x like "00????.SH";`$"99",2_string x;   x];};   /  CF与wind终端规范不同！！！！！！
mktmap:{[x]if[x in key mktmaps;:mktmaps[x]];:x;};
int2date:{:$[(type x)in(-6h;-7h);"D"$string x;(type x)in(6h;7h);"D"$/:string x;x]};     //   int2date 20150319  => 2015.03.19   
int2time:{:$[(type x)in(-6h;-7h);"T"$-9#"000000",string x;(type x)in(6h;7h);"T"$/:-9#/:"000000",/:string x];}   //  int2time 91400100 => 09:14:00.100      int2time 91400100 101400100
/连接服务器  
start:{[ip;port;user;password]if[not all (4#-11h)=type each (ip;port;user;password);:`errid`errmsg`data!(-1j;`arg_type_err;0j)];.windtdb.lastuser:user;
   r:`errid`errmsg`data!.windtdb.start[(ip;port;user;password;::)];if[r[`errid]<0;:r];r[`data]:`info`mktcount`mkts!(r[`data][0];r[`data][1];flip `mkt`date!flip 0N 2 # r[`data][2]);0N!(.z.T;r);:r;};
/断开服务器连接
stop:{[]r:`errid`errmsg`data!.windtdb.stop[];0N!(.z.T;r);:r;}; 
/读代码; getsyms[]读所有代码，getsyms[windmktmaps`SZ]读深市代码
sectypes:`index`stock`fund`bond`repo`warrant`futures`forex`call`put`bankrate`nmetal`other`exindex`ag`zxb`cyb`bg`hg`us`of`lof`etf`if`fut`warcall`warput!(0x00;0x10;0x20;0x30;0x40;0x60;0x70;0x80;0x90;0x91;0xd0;0xe0;0xf0;0x01;0x10;0x11;0x12;0x16;0x17;0x1a;0x21;0x22;0x23;0x70;0x71;0x61;0x62);
getsyms:{[mkt]r:`errid`errmsg`data!.windtdb.getsyms[($[null mkt;`;mkt];::)];if[r[`errid]<0;:r];r[`data]:update sectype:{sectypes?`byte$x}each ntype,sym:tdbsym2sym each windcode from flip `windcode`code`name`mkt`ntype!flip (0N;5) # 1_ r[`data];:r;};  
/读k线数据 
.windtdb.CYCTYPE:`SECOND`MINUTE`DAY`WEEK`MONTH`SEASON`HAFLYEAR`YEAR`TICKBAR!`int$til 9;
.windtdb.FQ:`NONE`BACKWARD`FORWARD!(0i;1i;2i);
gettdbbars:{[windcode;cyctype;cycdef;fqflag;autocomplete;startdt;enddt]if[not all (-11h,6#-6h)=type each (windcode;cyctype;cycdef;fqflag;autocomplete;startdt;enddt);:`errid`errmsg`data!(-1j;`arg_type_err;0j)];
  r:`errid`errmsg`data!.windtdb.getbars[(windcode;sym2windmkt[windcode];cyctype;cycdef;fqflag;autocomplete;startdt;enddt;0i;0i;::)];if[r[`errid]<0;:r];
  r[`data]:select date:int2date each date,sym:tdbsym2sym each sym,time:int2time each time,open,high,low,close,volume,openint:?[windcode like "*.S[HZ]";amount;openint] from flip `date`time`sym`open`high`low`close`volume`amount`openint`deals!flip (r[`data][0];r[`data][1]) # 2_ r[`data];:r;};
/获取快照数据`date`time`sym`close`volume
gettdbcsbar0:gettdbtick:{[windcode;ndate]if[not all (-11h,-6h)=type each (windcode;ndate);:`errid`errmsg`data!(-1j;`arg_type_err;0j)];
  r:`errid`errmsg`data!.windtdb.gettick[(windcode;sym2windmkt[windcode];ndate;0i;0i;::)];if[r[`errid]<0;:r];
  r[`data]:select date:int2date each date,sym:tdbsym2sym each sym,time:int2time each time,close,volume from flip `date`time`sym`close`volume!flip (r[`data][0];r[`data][1]) # 2_ r[`data];:r;};
/获取快照数据`date`time`sym`close`volume`openint,比gettdbtick多了openint字段
gettdbcsbar0_2:gettdbtick2:{[windcode;ndate]if[not all (-11h,-6h)=type each (windcode;ndate);:`errid`errmsg`data!(-1j;`arg_type_err;0j)];
  r:`errid`errmsg`data!.windtdb.gettick2[(windcode;sym2windmkt[windcode];ndate;0i;0i;::)];if[r[`errid]<0;:r];
  r[`data]:select date:int2date each date,sym:tdbsym2sym each sym,time:int2time each time,close,volume,openint from flip `date`time`sym`close`volume`openint!flip (r[`data][0];r[`data][1]) # 2_ r[`data];:r;};
/获取快照数据，含10档买卖盘
gettdbcstaq:gettdbtickAB:{[windcode;ndate]if[not all (-11h,-6h)=type each (windcode;ndate);:`errid`errmsg`data!(-1j;`arg_type_err;0j)];
  r:`errid`errmsg`data!.windtdb.gettickAB[(windcode;sym2windmkt[windcode];ndate;0i;0i;::)];if[r[`errid]<0;:r];
  mycolsname:(`date`time`sym`prevclose`open`high`low`close`volume`openint`bid`bsize`ask`asize),raze{(`$"bid",string x;`$"bsize",string x;`$"ask",string x;`$"asize",string x)}each 2+til 9;
  r[`data]:update sym:(tdbsym2sym each sym),date:("D"$/:string date),time:("T"$/:-9#/:"000000",/:string time) from flip mycolsname!flip (r[`data][0];r[`data][1]) # 2_ r[`data];:r;};

/获取期货快照数据(不带买卖盘口)
gettdbcfbar0:gettdbfuturetick:{[windcode;ndate]if[not all (-11h,-6h)=type each (windcode;ndate);:`errid`errmsg`data!(-1j;`arg_type_err;0j)];
  r:`errid`errmsg`data!.windtdb.getfuturetick[(windcode;sym2windmkt[windcode];ndate;0i;0i;::)];if[r[`errid]<0;:r];
  r[`data]:select date:int2date each date,sym:tdbsym2sym each sym,time:int2time each time,close,volume from flip `date`time`sym`close`volume!flip (r[`data][0];r[`data][1]) # 2_ r[`data];:r;};
/获取期货快照数据(不带买卖盘口)，比gettdbcfbar0:gettdbfuturetick多返回openint
gettdbcfbar0_2:gettdbfuturetick2:{[windcode;ndate]if[not all (-11h,-6h)=type each (windcode;ndate);:`errid`errmsg`data!(-1j;`arg_type_err;0j)];
  r:`errid`errmsg`data!.windtdb.getfuturetick2[(windcode;sym2windmkt[windcode];ndate;0i;0i;::)];if[r[`errid]<0;:r];
  r[`data]:select date:int2date each date,sym:tdbsym2sym each sym,time:int2time each time,close,volume,openint from flip `date`time`sym`close`volume`openint!flip (r[`data][0];r[`data][1]) # 2_ r[`data];:r;};
/获取期货快照数据(带买卖盘口)
gettdbcftaq:gettdbfuturetickAB:{[windcode;ndate]if[not all (-11h,-6h)=type each (windcode;ndate);:`errid`errmsg`data!(-1j;`arg_type_err;0j)];
  r:`errid`errmsg`data!.windtdb.getfuturetickAB[(windcode;sym2windmkt[windcode];ndate;0i;0i;::)];if[r[`errid]<0;:r];
  mycolsname:(`date`time`sym`prevclose`open`high`low`close`volume`openint`bid`bsize`ask`asize),raze{(`$"bid",string x;`$"bsize",string x;`$"ask",string x;`$"asize",string x)}each 2+til 4;
  r[`data]:update sym:(tdbsym2sym each sym),date:("D"$/:string date),time:("T"$/:-9#/:"000000",/:string time) from flip mycolsname!flip (r[`data][0];r[`data][1]) # 2_ r[`data];:r;};
/逐笔成交
gettdbbar00:gettdbtransaction:{[windcode;ndate]if[not all (-11h,-6h)=type each (windcode;ndate);:`errid`errmsg`data!(-1j;`arg_type_err;0j)];
  r:`errid`errmsg`data!.windtdb.gettransaction[(windcode;sym2windmkt[windcode];ndate;0i;0i;::)];if[r[`errid]<0;:r];
  mycolsname:`date`time`sym`close`volume`id`funccode`ordertype`bsflag;
  r[`data]:update sym:(tdbsym2sym each sym),date:("D"$/:string date),time:("T"$/:-9#/:"000000",/:string time) from flip mycolsname!flip (r[`data][0];r[`data][1]) # 2_ r[`data];:r;};
/逐笔委托
gettdborder:{[windcode;ndate]if[not all (-11h,-6h)=type each (windcode;ndate);:`errid`errmsg`data!(-1j;`arg_type_err;0j)];
  r:`errid`errmsg`data!.windtdb.getorder[(windcode;sym2windmkt[windcode];ndate;0i;0i;::)];if[r[`errid]<0;:r];
  mycolsname:`date`time`sym`price`volume`id`ordid`funccode`ordertype;
  r[`data]:update sym:(tdbsym2sym each sym),date:("D"$/:string date),time:("T"$/:-9#/:"000000",/:string time) from flip mycolsname!flip (r[`data][0];r[`data][1]) # 2_ r[`data];:r;};
/委托队列
gettdborderqueue:{[windcode;ndate]if[not all (-11h,-6h)=type each (windcode;ndate);:`errid`errmsg`data!(-1j;`arg_type_err;0j)];
  r:`errid`errmsg`data!.windtdb.getorderqueue[(windcode;sym2windmkt[windcode];ndate;0i;0i;::)];if[r[`errid]<0;:r];
  mycolsname:`date`time`sym`side`price`orderitems`abitems,raze {:`$"absize",string x;}each til 50;
  r[`data]:update sym:(tdbsym2sym each sym),date:("D"$/:string date),time:("T"$/:-9#/:"000000",/:string time) from flip mycolsname!flip (r[`data][0];r[`data][1]) # 2_ r[`data];:r;};
////进一步封装
getbar1m:getbar60:{[fesym;startdt;enddt]windcode:sym2tdbsym  fesym;startdt:"I"$(string startdt)_/4 6;enddt:"I"$(string enddt)_/4 6;:gettdbbars[windcode;.windtdb.CYCTYPE`MINUTE;1i;.windtdb.FQ`NONE;1i;startdt;enddt];};
getbar5m:getbar300:{[fesym;startdt;enddt]windcode:sym2tdbsym  fesym;startdt:"I"$(string startdt)_/4 6;enddt:"I"$(string enddt)_/4 6;:gettdbbars[windcode;.windtdb.CYCTYPE`MINUTE;5i;.windtdb.FQ`NONE;1i;startdt;enddt];};
getbar30m:getbar1800:{[fesym;startdt;enddt]windcode:sym2tdbsym  fesym;startdt:"I"$(string startdt)_/4 6;enddt:"I"$(string enddt)_/4 6;:gettdbbars[windcode;.windtdb.CYCTYPE`MINUTE;30i;.windtdb.FQ`NONE;1i;startdt;enddt];};
getbar1d:{[fesym;startdt;enddt]windcode:sym2tdbsym fesym;startdt:"I"$(string startdt)_/4 6;enddt:"I"$(string enddt)_/4 6;:gettdbbars[windcode;.windtdb.CYCTYPE`DAY;   1i;.windtdb.FQ`NONE;1i;startdt;enddt];};
getbarx:{[fesym;mysize;startdt;enddt]windcode:sym2tdbsym  fesym;startdt:"I"$(string startdt)_/4 6;enddt:"I"$(string enddt)_/4 6;:gettdbbars[windcode;.windtdb.CYCTYPE`SECOND;`int$mysize;.windtdb.FQ`NONE;1i;startdt;enddt];};
getbar0:   {[fesym;dt]windcode:sym2tdbsym fesym;dt:"I"$(string dt)_/4 6;:$[fesym like "*.S[HZ]";gettdbtick[windcode;dt];gettdbfuturetick[windcode;dt]];};
getbar0_2: {[fesym;dt]windcode:sym2tdbsym fesym;dt:"I"$(string dt)_/4 6;:$[fesym like "*.S[HZ]";gettdbtick2[windcode;dt];gettdbfuturetick2[windcode;dt]];}; //has openint
getbar00:  {[fesym;dt]windcode:sym2tdbsym fesym;dt:"I"$(string dt)_/4 6;:$[fesym like "*.S[HZ]";gettdbtransaction[windcode;dt];gettdbfuturetick[windcode;dt]];};
gettaq:    {[fesym;dt]windcode:sym2tdbsym fesym;dt:"I"$(string dt)_/4 6;:$[fesym like "*.S[HZ]";gettdbtickAB[windcode;dt];gettdbfuturetickAB[windcode;dt]];};

//一些工具函数
hdbpathstr:{:ssr[(-2_getenv[`qhome]);"\\";"/"],"/hdb/"};               // path for saving the data,              ended with "/" !!
hdbpath:{:hsym `$hdbpathstr[];};        / hdbpath[]
gethdbdates:{[t]:asc @[get;(`$":",(-2_getenv[`qhome]),"\\data\\hdbinfo\\",string[t],"_dates");()];}; /  gethdbdates[`csbar0]
sethdbdates:{[t;x]:$[14h=abs type x;(`$ssr[;"\\";"/"]":",(-2_getenv[`qhome]),"\\data\\hdbinfo\\",string[t],"_dates") set asc distinct gethdbdates[t],x;`para_must_be_date_or_datelist]};  /  sethdbdates[`csbar0;.z.D ]
delhdbdates:{[t;x]:$[14h=abs type x;(`$ssr[;"\\";"/"]":",(-2_getenv[`qhome]),"\\data\\hdbinfo\\",string[t],"_dates") set asc distinct (gethdbdates[t] except x);`para_must_be_date_or_datelist]};  / delhdbdates[`csbar0;.z.D]
//下载股票日线数据并保存到hdb
tdb2csbar1d:{[mydaterange]  "usage: mydaterange 形式如(.z.D-1;.z.D) ; ";             / mydaterange:(.z.D-1;.z.D)
    mysymlist:asc exec windcode from select from getsyms[][`data] where ((sectype in `exindex`stock`zxb`cyb`fund`etf`lof`call`put) and (not sym like "36*.SZ")and(name<>`)and (not name like "*\312\352")and (not name like "*(\267\302\325\346)"));  /  \312\352=赎   \267\302\325\346=仿真
    /mysymlist:`000001.SZ`600036.SH;
    r:gettdbbars[`399001.SZ;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i]; if[ r[`errid]<>0;:`error_tradedates];     /交易日
    tradedates:asc exec date from select distinct date from r[`data] ;
    mydates:tradedates[where tradedates within mydaterange];    /指定日期区间内的交易日
    mydates:mydates except gethdbdates[`csbar1d];    /计算实际需要下载数据的日期
    /下载数据并保存到hdb
    ii:0;do[count mydates;mydate:mydates[ii]; mypath:hsym`$hdbpathstr[],(string mydate),"/csbar1d/";  if[`downloadtime in key `.;if[not .z.T within downloadtime;stop[];exit 1]];
            cc:0;CSBAR1D::();do[count mysymlist;mysym:mysymlist[cc]; r:getbar1d[mysym;mydate;mydate];0N!(.z.T;mydate;tdbsym2sym[mysym];`csbar1d); 
                                $[r[`errid]=0;`CSBAR1D insert select tdbsym2sym each sym,open,high,low,close,volume from r[`data];0N!(.z.T;mydate;tdbsym2sym[mysym];r[`errmsg])];cc+:1]; 
                if[not CSBAR1D~(); (mypath;17;3;0) set .Q.en[hdbpath[]] `sym xasc CSBAR1D; @[mypath;`sym;`p#] ]; 
    sethdbdates[`csbar1d;mydate];ii+:1];
    //.Q.chk[hdbpath[]];
    };
//下载股票30m数据并保存到hdb
tdb2csbar30m:{[mydaterange]  "usage: mydaterange 形式如(.z.D-1;.z.D) ; ";             / mydaterange:(.z.D-5;.z.D)
    mysymlist:asc exec windcode from select from getsyms[][`data] where ((sectype in `exindex`stock`zxb`cyb`fund`etf`lof`call`put) and (not sym like "36*.SZ")and(name<>`)and (not name like "*\312\352")and (not name like "*(\267\302\325\346)"));  /  \312\352=赎   \267\302\325\346=仿真
    /mysymlist:`000001.SZ`600036.SH;
    r:gettdbbars[`399001.SZ;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i]; if[ r[`errid]<>0;:`error_tradedates];     /交易日
    tradedates:asc exec date from select distinct date from r[`data] ;
    mydates:tradedates[where tradedates within mydaterange];    /指定日期区间内的交易日
    mydates:mydates except gethdbdates[`csbar30m];    /计算实际需要下载数据的日期
    /下载数据并保存到hdb
    ii:0;do[count mydates;mydate:mydates[ii]; mypath:hsym`$hdbpathstr[],(string mydate),"/csbar30m/";  if[`downloadtime in key `.;if[not .z.T within downloadtime;stop[];exit 1]];
            cc:0;CSBAR30M::();do[count mysymlist;mysym:mysymlist[cc]; r:getbar30m[mysym;mydate;mydate];0N!(.z.T;mydate;tdbsym2sym[mysym];`csbar30m); 
                                $[r[`errid]=0;`CSBAR30M insert select tdbsym2sym each sym,time-00:30,open,high,low,close,volume from r[`data];0N!(.z.T;mydate;tdbsym2sym[mysym];r[`errmsg])];cc+:1]; 
                if[not CSBAR30M~(); (mypath;17;3;0) set .Q.en[hdbpath[]] update `p#sym from `sym xasc CSBAR30M ];  /@[mypath;`sym;`p#]
    sethdbdates[`csbar30m;mydate];ii+:1];
    //.Q.chk[hdbpath[]];
    };
//下载股票5m数据并保存到hdb
tdb2csbar5m:{[mydaterange]  "usage: mydaterange 形式如(.z.D-1;.z.D) ; ";             / mydaterange:(.z.D-5;.z.D)
    mysymlist:asc exec windcode from select from getsyms[][`data] where ((sectype in `exindex`stock`zxb`cyb`fund`etf`lof`call`put) and (not sym like "36*.SZ")and(name<>`)and (not name like "*\312\352")and (not name like "*(\267\302\325\346)"));  /  \312\352=赎   \267\302\325\346=仿真
    //mysymlist:`000001.SZ`600036.SH;
    r:gettdbbars[`399001.SZ;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i]; if[ r[`errid]<>0;:`error_tradedates];     /交易日
    tradedates:asc exec date from select distinct date from r[`data] ;
    mydates:tradedates[where tradedates within mydaterange];    /指定日期区间内的交易日
    mydates:mydates except gethdbdates[`csbar5m];    /计算实际需要下载数据的日期
    /下载数据并保存到hdb
    ii:0;do[count mydates;mydate:mydates[ii]; mypath:hsym`$hdbpathstr[],(string mydate),"/csbar5m/";  /if[`downloadtime in key `.;if[not .z.T within downloadtime;stop[];exit 1]];
            cc:0;CSBAR5M::();do[count mysymlist;mysym:mysymlist[cc]; r:getbar5m[mysym;mydate;mydate];0N!(.z.T;mydate;tdbsym2sym[mysym];`csbar5m); 
                                $[r[`errid]=0;`CSBAR5M insert select tdbsym2sym each sym,time-00:05,open,high,low,close,volume from r[`data];0N!(.z.T;mydate;tdbsym2sym[mysym];r[`errmsg])];cc+:1]; 
                if[not CSBAR5M~(); (mypath;17;3;6) set .Q.en[hdbpath[]] update `p#sym from `sym xasc CSBAR5M ];  /@[mypath;`sym;`p#]
    sethdbdates[`csbar5m;mydate];ii+:1];
    //.Q.chk[hdbpath[]];
    };
//下载股票1m数据并保存到hdb
tdb2csbar1m:{[mydaterange]  "usage: mydaterange 形式如(.z.D-1;.z.D) ; ";             / mydaterange:(.z.D-5;.z.D)
    mysymlist:asc exec windcode from select from getsyms[][`data] where ((sectype in `exindex`stock`zxb`cyb`fund`etf`lof`call`put) and (not sym like "36*.SZ")and(name<>`)and (not name like "*\312\352")and (not name like "*(\267\302\325\346)"));  /  \312\352=赎   \267\302\325\346=仿真
    //mysymlist:`000001.SZ`600036.SH;
    r:gettdbbars[`399001.SZ;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i]; if[ r[`errid]<>0;:`error_tradedates];     /交易日
    tradedates:asc exec date from select distinct date from r[`data] ;
    mydates:tradedates[where tradedates within mydaterange];    /指定日期区间内的交易日
    mydates:mydates except gethdbdates[`csbar1m];    /计算实际需要下载数据的日期
    /下载数据并保存到hdb
    ii:0;do[count mydates;mydate:mydates[ii]; mypath:hsym`$hdbpathstr[],(string mydate),"/csbar1m/";  /if[`downloadtime in key `.;if[not .z.T within downloadtime;stop[];exit 1]];
            cc:0;CSBAR::();do[count mysymlist;mysym:mysymlist[cc]; r:getbar5m[mysym;mydate;mydate];0N!(.z.T;mydate;tdbsym2sym[mysym];`csbar1m); 
                                $[r[`errid]=0;`CSBAR insert select tdbsym2sym each sym,time-00:01,open,high,low,close,volume from r[`data];0N!(.z.T;mydate;tdbsym2sym[mysym];r[`errmsg])];cc+:1]; 
                if[not CSBAR~(); (mypath;17;3;0) set .Q.en[hdbpath[]] update `p#sym from `sym xasc CSBAR ];  /@[mypath;`sym;`p#]
    sethdbdates[`csbar1m;mydate];ii+:1];
    //.Q.chk[hdbpath[]];
    };    
//下载股票taq数据并保存到hdb
tdb2cstaq:{[mydaterange]  "usage: mydaterange 形式如(.z.D-1;.z.D) ; ";             / mydaterange:(.z.D-1;.z.D)
    mysymlist:asc exec windcode from select from getsyms[][`data] where ((sectype in `exindex`stock`zxb`cyb`fund`etf`lof`call`put) and (not sym like "36*.SZ")and(name<>`)and (not name like "*\312\352")and (not name like "*(\267\302\325\346)"));  /  \312\352=赎   \267\302\325\346=仿真
    //mysymlist:`000001.SZ`600036.SH;
    r:gettdbbars[`399001.SZ;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i]; if[ r[`errid]<>0;:`error_tradedates];     /交易日
    tradedates:asc exec date from select distinct date from r[`data] ;
    mydates:tradedates[where tradedates within mydaterange];    //指定日期区间内的交易日
    mydates:mydates except gethdbdates[`cstaq];    //计算实际需要下载数据的日期
    //下载数据并保存到hdb
    ii:0;do[count mydates;mydate:mydates[ii]; cstaqpath:hsym`$hdbpathstr[],(string mydate),"/cstaq/"; if[`downloadtime in key `.;if[not .z.T within downloadtime;stop[];exit 1]];
            cc:0;do[count mysymlist;mysym:mysymlist[cc]; r:gettaq[mysym;mydate];0N!(.z.T;mydate;tdbsym2sym[mysym];`cstaq); 
                $[(r[`errid]=0)&98h=type r[`data];  $[cc=0; (cstaqpath;17;3;0) set .Q.en[hdbpath[]] select tdbsym2sym each sym,time,prevclose,open,high,low,close,volume,bid,bsize,ask,asize,bid2,bsize2,ask2,asize2,bid3,bsize3,ask3,asize3,bid4,bsize4,ask4,asize4,bid5,bsize5,ask5,asize5 from r[`data];cstaqpath upsert .Q.en[hdbpath[]] select tdbsym2sym each sym,time,prevclose,open,high,low,close,volume,bid,bsize,ask,asize,bid2,bsize2,ask2,asize2,bid3,bsize3,ask3,asize3,bid4,bsize4,ask4,asize4,bid5,bsize5,ask5,asize5 from r[`data] ];0N!(.z.T;mydate;tdbsym2sym[mysym];r[`errmsg])];
                cc+:1];  @[cstaqpath;`sym;`p#];
         sethdbdates[`cstaq;mydate];ii+:1];
    //.Q.chk[hdbpath[]];
    };
//下载股票taq数据并保存到hdb;每天数据先保存在内存表再保存到磁盘
tdb2mem2cstaq:tdb2cstaq2:{[mydaterange]  "usage: mydaterange 形式如(.z.D-1;.z.D) ; ";             / mydaterange:(.z.D-1;.z.D)
    mysymlist:asc exec windcode from select from getsyms[][`data] where ((sectype in `exindex`stock`zxb`cyb`fund`etf`lof`call`put) and (not sym like "36*.SZ")and(name<>`)and (not name like "*\312\352")and (not name like "*(\267\302\325\346)"));  /  \312\352=赎   \267\302\325\346=仿真
    //mysymlist:`000001.SZ`600036.SH;
    r:gettdbbars[`399001.SZ;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i]; if[ r[`errid]<>0;:`error_tradedates];     /交易日
    tradedates:asc exec date from select distinct date from r[`data] ;
    mydates:tradedates[where tradedates within mydaterange];    //指定日期区间内的交易日
    mydates:mydates except gethdbdates[`cstaq];    //计算实际需要下载数据的日期
    //下载数据并保存到hdb
    ii:0;do[count mydates;mydate:mydates[ii]; cstaqpath:hsym`$hdbpathstr[],(string mydate),"/cstaq/"; if[`downloadtime in key `.;if[not .z.T within downloadtime;stop[];exit 1]];TMPTBL::();
            cc:0;do[count mysymlist;mysym:mysymlist[cc]; r:gettaq[mysym;mydate];0N!(.z.T;mydate;tdbsym2sym[mysym];`cstaq); 
                $[(r[`errid]=0)&98h=type r[`data];  `TMPTBL insert select tdbsym2sym each sym,time,prevclose,open,high,low,close,volume,bid,bsize,ask,asize,bid2,bsize2,ask2,asize2,bid3,bsize3,ask3,asize3,bid4,bsize4,ask4,asize4,bid5,bsize5,ask5,asize5 from r[`data];    0N!(.z.T;mydate;tdbsym2sym[mysym];r[`errmsg])];
                cc+:1];  
                if[98h=type TMPTBL;(cstaqpath;17;3;0) set .Q.en[hdbpath[]] TMPTBL; @[cstaqpath;`sym;`p#]; TMPTBL::()];
         sethdbdates[`cstaq;mydate];ii+:1];
    };    
//下载股票taq数据并追加到hdb，注意是追加，而且没有判断追加的数据是否已经存在，应小心！！！
append2cstaq:{[mydaterange;mysyms]  "append2cstaq[(.z.D-1;.z.D);`510300.SH`510500.SH] ";    // mydaterange:(.z.D-1;.z.D)
    //mysymlist:asc exec windcode from select from getsyms[][`data] where ((sectype in `exindex`stock`zxb`cyb`etf`lof`call`put) and (not sym like "36*.SZ")and(name<>`)and (not name like "*\312\352")and (not name like "*(\267\302\325\346)"));  /  \312\352=赎   \267\302\325\346=仿真
    mysymlist:mysyms;  //`510300.SH`510500.SH`159915.SZ;
    r:gettdbbars[`399001.SZ;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i]; if[ r[`errid]<>0;:`error_tradedates];     /交易日
    tradedates:asc exec date from select distinct date from r[`data] ;
    mydates:tradedates[where tradedates within mydaterange];    /指定日期区间内的交易日
    //!!!mydates:mydates except gethdbdates[`cstaq];    /计算实际需要下载数据的日期
    /下载数据并保存到hdb
    ii:0;do[count mydates;mydate:mydates[ii]; cstaqpath:hsym`$hdbpathstr[],(string mydate),"/cstaq/"; if[`downloadtime in key `.;if[not .z.T within downloadtime;stop[];exit 1]];TMPTBL::();
            cc:0;do[count mysymlist;mysym:mysymlist[cc]; r:gettaq[mysym;mydate];0N!(.z.T;mydate;tdbsym2sym[mysym];`append2cstaq); 
                $[r[`errid]=0; `TMPTBL insert select tdbsym2sym each sym,time,prevclose,open,high,low,close,volume,bid,bsize,ask,asize,bid2,bsize2,ask2,asize2,bid3,bsize3,ask3,asize3,bid4,bsize4,ask4,asize4,bid5,bsize5,ask5,asize5 from r[`data] ;0N!(.z.T;mydate;tdbsym2sym[mysym];r[`errmsg])];
            cc+:1];
            if[98h=type TMPTBL;cstaqpath upsert .Q.en[hdbpath[]] TMPTBL; @[cstaqpath;`sym;`p#]; TMPTBL::()];
    ///sethdbdates[`cstaq;mydate];
    ii+:1];
    //.Q.chk[hdbpath[]];
    };

/下载股票逐笔成交数据并保存到hdb
tdb2csbar0:{[mydaterange]  "usage: mydaterange 形式如(.z.D-1;.z.D) ; ";             / mydaterange:(.z.D-1;.z.D)
    mysymlist:asc exec windcode from select from getsyms[][`data] where ((sectype in `exindex`stock`zxb`cyb`fund`etf`lof`call`put) and (not sym like "36*.SZ")and(name<>`)and (not name like "*\312\352")and (not name like "*(\267\302\325\346)"));  /  \312\352=赎   \267\302\325\346=仿真
    /mysymlist:`000001.SZ`600036.SH;
    r:gettdbbars[`399001.SZ;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i]; if[ r[`errid]<>0;:`error_tradedates];     /交易日
    tradedates:asc exec date from select distinct date from r[`data] ;
    mydates:tradedates[where tradedates within mydaterange];    /指定日期区间内的交易日
    mydates:mydates except gethdbdates[`csbar0];    /计算实际需要下载数据的日期
    /下载数据并保存到hdb
    ii:0;do[count mydates;mydate:mydates[ii]; csbar0path:hsym`$hdbpathstr[],(string mydate),"/csbar0/"; if[`downloadtime in key `.;if[not .z.T within downloadtime;stop[];exit 1]];
            cc:0;do[count mysymlist;mysym:mysymlist[cc]; r:getbar00[mysym;mydate];0N!(.z.T;mydate;tdbsym2sym mysym;`csbar0); 
                $[(r[`errid]=0)&98h=type r[`data];  $[cc=0; (csbar0path;17;3;0) set .Q.en[hdbpath[]]  select tdbsym2sym each sym,time,close,volume from r[`data];csbar0path upsert .Q.en[hdbpath[]] select tdbsym2sym each sym,time,close,volume from r[`data] ];0N!(.z.T;mydate;tdbsym2sym mysym;r[`errmsg])];
                cc+:1]; @[csbar0path;`sym;`p#];
         sethdbdates[`csbar0;mydate];ii+:1];
    //.Q.chk[hdbpath[]];
    };
/下载股票逐笔成交数据并保存到hdb;每天数据先保存在内存表再保存到磁盘
tdb2mem2csbar0:{[mydaterange]  "usage: mydaterange 形式如(.z.D-1;.z.D) ; ";             / mydaterange:(.z.D-1;.z.D)
    mysymlist:asc exec windcode from select from getsyms[][`data] where ((sectype in `exindex`stock`zxb`cyb`fund`etf`lof`call`put) and (not sym like "36*.SZ")and(name<>`)and (not name like "*\312\352")and (not name like "*(\267\302\325\346)"));  /  \312\352=赎   \267\302\325\346=仿真
    /mysymlist:`000001.SZ`600036.SH;
    r:gettdbbars[`399001.SZ;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i]; if[ r[`errid]<>0;:`error_tradedates];     /交易日
    tradedates:asc exec date from select distinct date from r[`data] ;
    mydates:tradedates[where tradedates within mydaterange];    /指定日期区间内的交易日
    mydates:mydates except gethdbdates[`csbar0];    /计算实际需要下载数据的日期
    /下载数据并保存到hdb
    ii:0;do[count mydates;mydate:mydates[ii]; csbar0path:hsym`$hdbpathstr[],(string mydate),"/csbar0/"; if[`downloadtime in key `.;if[not .z.T within downloadtime;stop[];exit 1]];TMPTBL::();
            cc:0;do[count mysymlist;mysym:mysymlist[cc]; r:getbar00[mysym;mydate];0N!(.z.T;mydate;mysym;`csbar0); 
                $[(r[`errid]=0)&98h=type r[`data];  `TMPTBL insert select tdbsym2sym each sym,time,close,volume from r[`data] ;
                  0N!(.z.T;mydate;mysym;r[`errmsg])];
                cc+:1]; 
                if[98h=type TMPTBL;(csbar0path;17;3;0) set .Q.en[hdbpath[]] update `p#sym from TMPTBL; TMPTBL::()];
         sethdbdates[`csbar0;mydate];ii+:1];
    //.Q.chk[hdbpath[]];
    };    
/下载CFE日线数据并保存到hdb
tdb2cfbar1d:{[mydaterange]  "usage: mydaterange 形式如(.z.D-1;.z.D) ; ";             / mydaterange:(.z.D-1;.z.D)
    mysymlist:asc exec windcode from select from getsyms[][`data] where ((sectype in `fut`futures) and (not name like "*(\267\302\325\346)"));  /     \267\302\325\346=仿真
    /mysymlist:`000001.SZ`600036.SH;
    r:gettdbbars[`399001.SZ;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i]; if[ r[`errid]<>0;:`error_tradedates];     /交易日
    tradedates:asc exec date from select distinct date from r[`data] ;
    mydates:tradedates[where tradedates within mydaterange];    /指定日期区间内的交易日
    mydates:mydates except gethdbdates[`cfbar1d];    /计算实际需要下载数据的日期
    /下载数据并保存到hdb
    ii:0;do[count mydates;mydate:mydates[ii]; mypath:hsym`$hdbpathstr[],(string mydate),"/cfbar1d/";  if[`downloadtime in key `.;if[not .z.T within downloadtime;stop[];exit 1]];
            cc:0;CFBAR1D::();do[count mysymlist;mysym:mysymlist[cc]; r:getbar1d[mysym;mydate;mydate];0N!(.z.T;mydate;tdbsym2sym[mysym];`cfbar1d); 
                                $[r[`errid]=0;`CFBAR1D insert select tdbsym2sym each sym,open,high,low,close,volume from r[`data];0N!(.z.T;mydate;tdbsym2sym[mysym];r[`errmsg])];cc+:1]; 
                if[not CFBAR1D~(); (mypath;17;3;0) set .Q.en[hdbpath[]] `sym xasc CFBAR1D; @[mypath;`sym;`p#] ]; 
    sethdbdates[`cfbar1d;mydate];ii+:1];
    //.Q.chk[hdbpath[]];
    };
/下载CFE bar1m并保存到hdb
tdb2mem2cfebar1m:{[mydaterange]  "usage: mydaterange 形式如(.z.D-1;.z.D) ; "; // mydaterange:(.z.D-1;.z.D)
    cfsymsdates:$[-11h=type key cfsym_tradedate:(`$":",(-2_getenv[`qhome]),"\\data\\hdbinfo\\cfsym_tradedate.csv");`sym`dt0`dt1 xcol("SDD";enlist",") 0: cfsym_tradedate;([]sym:`$();dt0:`date$();dt1:`date$())];   //合约的起止交易日
    mysymlist:asc exec windcode from select from getsyms[][`data] where ((sectype in `fut`futures) and (not name like "*(*") );  //     \267\302\325\346=仿真
    //mysymlist:`000001.SZ`600036.SH;
    r: gettdbbars[`399001.SZ;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i];    /交易日
    r1:gettdbbars[`000001.SH;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i];
    r2:gettdbbars[`IF.CFE;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i];
    tradedates:exec date from `date xasc select distinct date from r[`data],r1[`data],r2[`data] ;
    mydates:tradedates[where tradedates within mydaterange];    /指定日期区间内的交易日
    mydates:mydates except gethdbdates[`cfbar1m];    /计算实际需要下载数据的日期
    //下载数据并保存到hdb
    ii:0;do[count mydates;mydate:mydates[ii]; mypath:hsym`$hdbpathstr[],(string mydate),"/cfbar1m/";  if[`downloadtime in key `.;if[not .z.T within downloadtime;stop[];exit 1]];
            cc:0;CFBAR::();do[count mysymlist;mysym:mysymlist[cc];mysym1:tdbsym2sym(mysym);
            if[0=count select from cfsymsdates where sym=mysym1,(mydate<dt0)or(mydate>dt1);
             r:getbar1m[mysym;mydate;mydate];0N!(.z.T;mydate;mysym1;`cfbar1m); 
             $[r[`errid]=0;`CFBAR insert select sym:mysym1,time,open,high,low,close,volume from r[`data];0N!(.z.T;mydate;mysym1;r[`errmsg])];
            ];cc+:1]; 
            if[not CFBAR~(); (mypath;17;3;0) set .Q.en[hdbpath[]] `sym xasc CFBAR; @[mypath;`sym;`p#] ]; 
    sethdbdates[`cfbar1m;mydate];ii+:1];
    //.Q.chk[hdbpath[]];
    };    

/下载SHF/DCE/CZC bar1m并保存到hdb,追加方式，请先运行tdb2mem2cfebar1m
tdb2mem2cmbar1m:{[mydaterange]  "usage: mydaterange 形式如(.z.D-1;.z.D) ; "; // mydaterange:(.z.D-1;.z.D)
    cfsymsdates:$[-11h=type key cfsym_tradedate:(`$":",(-2_getenv[`qhome]),"\\data\\hdbinfo\\cfsym_tradedate.csv");`sym`dt0`dt1 xcol("SDD";enlist",") 0: cfsym_tradedate;([]sym:`$();dt0:`date$();dt1:`date$())];   //合约的起止交易日
    mysymlist:asc exec windcode from select from getsyms[][`data] where ((sectype in `fut`futures) and (not name like "*(*")  and (not sym like "*_*") );  //     \267\302\325\346=仿真
    //mysymlist:`000001.SZ`600036.SH;
    r:gettdbbars[`rb.SHF;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i];
    r1:gettdbbars[`ru.SHF;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i];
    r2:gettdbbars[`i.DCE;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i];
    tradedates:asc distinct 2014.12.29,exec date from `date xasc select distinct date from r[`data],r1[`data],r2[`data] ;
    mydates:tradedates[where tradedates within mydaterange];    /指定日期区间内的交易日
    mydates:mydates except gethdbdates[`cmbar1m];    /计算实际需要下载数据的日期
    //下载数据并保存到hdb
    ii:0;do[count mydates;mydate:mydates[ii]; mypath:hsym`$hdbpathstr[],(string mydate),"/cfbar1m/";  if[`downloadtime in key `.;if[not .z.T within downloadtime;stop[];exit 1]];
            cc:0;CFBAR::();do[count mysymlist;mysym:mysymlist[cc];mysym1:tdbsym2sym(mysym);
            if[0=count select from cfsymsdates where sym=mysym1,(mydate<dt0)or(mydate>dt1);
             r:getbar1m[mysym;mydate;mydate];0N!(.z.T;mydate;mysym1;`cfbar1m); 
             $[r[`errid]=0;`CFBAR insert select sym:mysym1,time,open,high,low,close,volume from r[`data];0N!(.z.T;mydate;mysym1;r[`errmsg])];
            ];cc+:1]; 
            if[not CFBAR~(); .[mypath;();,;.Q.en[hdbpath[]] `sym xasc CFBAR]; @[mypath;`sym;`p#] ];   //追加方式
    sethdbdates[`cmbar1m;mydate];ii+:1];
    }; 

/下载CFE bar0/tick并保存到hdb
tdb2mem2cfebar0:{[mydaterange]  "usage: mydaterange 形式如(.z.D-1;.z.D) ; "; // mydaterange:(.z.D-1;.z.D)
    cfsymsdates:$[-11h=type key cfsym_tradedate:(`$":",(-2_getenv[`qhome]),"\\data\\hdbinfo\\cfsym_tradedate.csv");`sym`dt0`dt1 xcol("SDD";enlist",") 0: cfsym_tradedate;([]sym:`$();dt0:`date$();dt1:`date$())];   //合约的起止交易日
    mysymlist:asc exec windcode from select from getsyms[][`data] where ((sectype in `fut`futures) and (not name like "*(*") );  //     \267\302\325\346=仿真
    //mysymlist:`000001.SZ`600036.SH;
    r: gettdbbars[`399001.SZ;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i];    /交易日
    r1:gettdbbars[`600000.SH;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i];
    r2:gettdbbars[`IFC1.CFE;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i];
    tradedates:exec date from `date xasc select distinct date from r[`data],r1[`data],r2[`data] ;
    mydates:tradedates[where tradedates within mydaterange];    /指定日期区间内的交易日
    mydates:mydates except gethdbdates[`cfebar0];    /计算实际需要下载数据的日期
    //下载数据并保存到hdb
    ii:0;do[count mydates;mydate:mydates[ii]; mypath:hsym`$hdbpathstr[],(string mydate),"/cfbar0/";  if[`downloadtime in key `.;if[not .z.T within downloadtime;stop[];exit 1]];
            cc:0;CFBAR::();do[count mysymlist;mysym:mysymlist[cc];mysym1:tdbsym2sym(mysym);
            if[0=count select from cfsymsdates where sym=mysym1,(mydate<dt0)or(mydate>dt1);
             r:getbar0[mysym;mydate];0N!(.z.T;mydate;mysym1;`cfebar0); 
             $[r[`errid]=0;`CFBAR insert select sym:mysym1,time,close,volume from r[`data];0N!(.z.T;mydate;mysym1;r[`errmsg])];
            ];cc+:1]; 
            if[not CFBAR~(); (mypath;17;3;0) set .Q.en[hdbpath[]] `sym xasc CFBAR; @[mypath;`sym;`p#] ]; 
    sethdbdates[`cfebar0;mydate];ii+:1];
    //.Q.chk[hdbpath[]];
    };    

/下载SHF/DCE/CZC bar0并保存到hdb,追加方式，请先运行tdb2mem2cfebar0
tdb2mem2cmbar0:{[mydaterange]  "usage: mydaterange 形式如(.z.D-1;.z.D) ; "; // mydaterange:(.z.D-1;.z.D)
    cfsymsdates:$[-11h=type key cfsym_tradedate:(`$":",(-2_getenv[`qhome]),"\\data\\hdbinfo\\cfsym_tradedate.csv");`sym`dt0`dt1 xcol("SDD";enlist",") 0: cfsym_tradedate;([]sym:`$();dt0:`date$();dt1:`date$())];   //合约的起止交易日
    mysymlist:asc exec windcode from select from getsyms[][`data] where ((sectype in `fut`futures) and (not name like "*(*")  and (not sym like "*_*")  and (not sym like "*-*") );  //     \267\302\325\346=仿真
    //mysymlist:`000001.SZ`600036.SH;
    r:gettdbbars[`rb.SHF;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i];
    r1:gettdbbars[`ru.SHF;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i];
    r2:gettdbbars[`i.DCE;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i];
    tradedates:asc distinct 2014.12.29,exec date from `date xasc select distinct date from r[`data],r1[`data],r2[`data] ;
    mydates:tradedates[where tradedates within mydaterange];    /指定日期区间内的交易日
    mydates:mydates except gethdbdates[`cmbar0];    /计算实际需要下载数据的日期
    //下载数据并保存到hdb
    ii:0;do[count mydates;mydate:mydates[ii]; mypath:hsym`$hdbpathstr[],(string mydate),"/cfbar0/";  if[`downloadtime in key `.;if[not .z.T within downloadtime;stop[];exit 1]];
            cc:0;CFBAR::();do[count mysymlist;mysym:mysymlist[cc];mysym1:tdbsym2sym(mysym);
            if[0=count select from cfsymsdates where sym=mysym1,(mydate<dt0)or(mydate>dt1);
             r:getbar0[mysym;mydate];0N!(.z.T;mydate;mysym1;`cmbar0); 
             $[r[`errid]=0;`CFBAR insert select sym:mysym1,time,close,volume from r[`data];0N!(.z.T;mydate;mysym1;r[`errmsg])];
            ];cc+:1]; 
            if[not CFBAR~(); .[mypath;();,;.Q.en[hdbpath[]] `sym xasc CFBAR]; @[mypath;`sym;`p#] ];   //追加方式
    sethdbdates[`cmbar0;mydate];ii+:1];
    };     
/下载CFE tick/bar0数据并保存到hdb
tdb2cfbar0:{[mydaterange]  "usage: mydaterange 形式如(.z.D-1;.z.D) ; ";  
    mysymlist:asc exec windcode from select from getsyms[][`data] where ((sectype in `fut`futures) and (not name like "*(\267\302\325\346)"));  /     \267\302\325\346=仿真
    r: gettdbbars[`399001.SZ;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i];    /交易日
    r1:gettdbbars[`000001.SH;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i];
    r2:gettdbbars[`IF.CFE;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i];
    tradedates:asc distinct 2014.12.29,exec date from `date xasc select distinct date from r[`data],r1[`data],r2[`data] ;   /交易日
    mydates:tradedates[where tradedates within mydaterange]; /指定日期区间内的交易日
    mydates:mydates except gethdbdates[`cfbar0]; /计算实际需要下载数据的日期
    /下载数据并保存到hdb
    ii:0;do[count mydates;mydate:mydates[ii]; cftaqpath:hsym`$hdbpathstr[],(string mydate),"/cfbar0/"; if[`downloadtime in key `.;if[not .z.T within downloadtime;stop[];exit 1]];
            cc:0;do[count mysymlist;mysym:mysymlist[cc]; r:getbar0[mysym;mydate];0N!(.z.T;mydate;mysym); 
                $[r[`errid]=0;  $[cc=0; (cftaqpath;17;3;0) set .Q.en[hdbpath[]]  select sym,time,close,volume from r[`data];cftaqpath upsert .Q.en[hdbpath[]] select sym,time,close,volume from r[`data] ];0N!(.z.T;mydate;mysym;r[`errmsg])];
                cc+:1];@[cftaqpath;`sym;`p#];
         sethdbdates[`cfbar0;mydate];ii+:1];
    / .Q.chk[hdbpath[]];
    };
/下载SHF tick/bar0数据并保存到hdb,追加方式!!!
tdb2shfbar0:{[mydaterange]  "usage: mydaterange 形式如(.z.D-1;.z.D) ; ";  
    mysymlist:asc exec windcode from select from getsyms[][`data] where ((sectype in `fut`futures) and (sym like "RB*.SHF") and (not name like "*(\267\302\325\346)"));  /     \267\302\325\346=仿真
    r:gettdbbars[`rb.SHF;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i];
    r1:gettdbbars[`ru.SHF;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i];
    r2:gettdbbars[`i.DCE;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i];
    tradedates:exec date from `date xasc select distinct date from r[`data],r1[`data],r2[`data] ;
    mydates:tradedates[where tradedates within mydaterange]; /指定日期区间内的交易日
    /下载数据并保存到hdb
    ii:0;do[count mydates;mydate:mydates[ii]; cftaqpath:hsym`$hdbpathstr[],(string mydate),"/cfbar0/";isnew:-11h=type@[get;cftaqpath;`];  if[`downloadtime in key `.;if[not .z.T within downloadtime;stop[];exit 1]];
            cc:0;do[count mysymlist;mysym:mysymlist[cc]; r:getbar0[mysym;mydate];0N!(.z.T;mydate;mysym); 
                $[r[`errid]=0; [  $[isnew;(cftaqpath;17;3;0) set .Q.en[hdbpath[]]  select sym,time,close,volume from r[`data];cftaqpath upsert .Q.en[hdbpath[]] select sym,time,close,volume from r[`data] ]; isnew:0b];0N!(.z.T;mydate;mysym;r[`errmsg])];
                cc+:1];@[cftaqpath;`sym;`p#];
         sethdbdates[`cfbar0;mydate];ii+:1];
    / .Q.chk[hdbpath[]];
    };
/下载期货taq数据并保存到hdb
tdb2cftaq:{[mydaterange]  "usage: mydaterange 形式如(.z.D-1;.z.D) ; ";   /  
    mysymlist:asc exec windcode from select from getsyms[][`data] where ((sectype in `fut`futures) and (not name like "*(\267\302\325\346)"));  /     \267\302\325\346=仿真
    r:gettdbbars[`399001.SZ;.windtdb.CYCTYPE`DAY;1i;.windtdb.FQ`NONE;0i;20100101i;20990101i]; if[ r[`errid]<>0;:`error_tradedates]; tradedates:asc distinct 2014.12.29,exec date from select distinct date from r[`data] ;   /交易日
    mydates:tradedates[where tradedates within mydaterange]; /指定日期区间内的交易日
    mydates:mydates except gethdbdates[`cftaq]; /计算实际需要下载数据的日期
    /下载数据并保存到hdb
    ii:0;do[count mydates;mydate:mydates[ii]; cftaqpath:hsym`$hdbpathstr[],(string mydate),"/cftaq/";  if[`downloadtime in key `.;if[not .z.T within downloadtime;stop[];exit 1]];
            cc:0;do[count mysymlist;mysym:mysymlist[cc]; r:gettaq[mysym;mydate];0N!(.z.T;mydate;mysym); 
                $[r[`errid]=0;  $[cc=0; (cftaqpath;17;3;0) set .Q.en[hdbpath[]] select tdbsym2sym each sym,time,prevclose,open,high,low,close,volume,bid,bsize,ask,asize,bid2,bsize2,ask2,asize2,bid3,bsize3,ask3,asize3,bid4,bsize4,ask4,asize4,bid5,bsize5,ask5,asize5 from r[`data];cftaqpath upsert .Q.en[hdbpath[]] select tdbsym2sym each sym,time,prevclose,open,high,low,close,volume,bid,bsize,ask,asize,bid2,bsize2,ask2,asize2,bid3,bsize3,ask3,asize3,bid4,bsize4,ask4,asize4,bid5,bsize5,ask5,asize5 from r[`data] ];0N!(.z.T;mydate;mysym;r[`errmsg])];
                cc+:1];@[cftaqpath;`sym;`p#];
         sethdbdates[`cftaq;mydate];ii+:1];
    / .Q.chk[hdbpath[]];
    };


\
   \l windtdb.q
    a: start[`ip;`port;`user;`pwd]                stop[]                 count r[`data]            meta    r`data       100#r[`data]
    .windtdb.lastuser
    r: getsyms[`] ;   r`data
    r: gettdbbars[`IF1503.CF;.windtdb.CYCTYPE`TICKBAR;5i;.windtdb.FQ`NONE;0i;20150318i;20150319i]
    r: gettdbbars[`IF1503.CF;.windtdb.CYCTYPE`SECOND;60i;.windtdb.FQ`NONE;0i;20150319i;20150319i]
    r: gettdbtick[`000001.SZ;20140104i;20150509i]
    r: gettdbtickAB[`000001.SZ;20140104i;20150509i]
    r: gettdbtick[`IF1505.CF;20150504i;20150504i;0i]
    r: gettdbtickAB[`IF1505.CF;20150504i;20150504i;0i]
    r: gettdbtransaction[`000001.SZ;20150504i;20150504i]
    r: gettdborder[`000001.SZ;20150504i;20150504i]
    r: gettdborderqueue[`000001.SZ;20150504i;20150504i]
    r:getbar1m[`IF1503.CFE;.z.D-1;.z.D] 
    r:getbar0[`IF1503.CFE;.z.D;.z.D] 
    r:getbar00[`000001.SZ;2015.05.05;.z.D]   
