/ Usage: q rdb.q [TP handle] [HDB handle]
/ Example: q rdb.q host:port :port


if[2 <> count .z.x; '"ERROR: args should be TP & HDB handles"];
tp: `$":",.z.x 0;
hdb: `$":",.z.x 1;

/ why sleep on linux?
/ if[not "w"=first string .z.o;system "sleep 1"];

upd:insert;

/ save tables down to hdb, clear tables, and tell hdb to reload
/ clearing tables removes attributes so reapply
eod:{t:tables`.;t@:where `g=attr each t@\:`sym;.Q.hdpf[hdb;`:.;x;`sym];@[;`sym;`g#] each t;};

/ init schema and sync up from log file;cd to hdb(so client save can run)
.u.rep:{(.[;();:;].)each x;if[null first y;:()];-11!y;system "cd ",1_-10_string first reverse y};
/ x: schema, y: (logcount; log)
/ .[.[;();:;]; ] each x     this creates the (empty) table for each table in the schema
/ HARDCODE \cd if other than logdir/db

/ connect to ticker plant for (schema;(logcount;log))
.u.rep .(hopen tp)"(.u.sub[`;`];`.u `i`L)";
/ .[.u.rep; list of args]

