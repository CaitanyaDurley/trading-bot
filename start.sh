mkdir -p hdb
nohup q tp.q schema.q tplog -p 5001 > tp.log 2>&1 &
nohup q rdb.q :5001 :5003 -p 5002 > rdb.log 2>&1 &
nohup q fh.q :5001 -p 5000 > fh.log 2>&1 &
nohup q hdb.q -p 5003 > hdb.log 2>&1 &
nohup q bot.q :5001 :5002 :5003 -p 5004 > bot.log 2>&1 &
