/ Usage: q rdb.q [TP handle] [HDB handle] -p [RDB port]
/ Example: q rdb.q :5001 :5003 -p 5002

if[not system"p";'"ERROR: please specify a port to listen on"];
if[2 <> count .z.x; '"ERROR: args should be TP & HDB handles"];
tp: `$":",.z.x 0;
hdb: `$":",.z.x 1;

/ why sleep on linux?
/ if[not "w"=first string .z.o;system "sleep 1"];

upd: {[tab; newData]
    tab insert newData;
    if[tab = `quotes;
        j: min exec last i by sym from quotes where i < (count quotes) - count newData;
        update fills bid, fills ask, fills bsize, fills asize by sym from `quotes where i >= j
    ];
 }

/ save tables down to hdb, clear tables, and tell hdb to reload
/ clearing tables removes attributes so reapply
.u.eod: {[today]
    t: tables`.;
    t@: where `g=attr each t@\:`sym;
    .Q.hdpf[hdb; `:hdb; today; `sym];
    @[; `sym; `g#] each t;
 }

/ create tables from schema & replay log file
init: {[schema; tplog]
    (.[;();:;].) each schema;
    -11!tplog;
 }

/ get (schema; tplog handle) from TP
init . (hopen tp)"(.u.sub[`;`]; .u.L)";
/ keep connection open so can receive updates from TP
