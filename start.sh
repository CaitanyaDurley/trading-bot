mkdir -p hdb
nohup q tp.q schema.q tplog -p 5001 > tp.log
nohup q rdb.q :5001 :5003 -p 5002 > rdb.log
nohup q fh.q :5001 -p 5000 > fh.log
nohup q bot.q :5001 :5002 :5003 -p 5004 > bot.log
