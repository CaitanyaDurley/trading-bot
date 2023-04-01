/ Usage: q bot.q [TP handle] [RDB handle] [HDB handle] -p [bot port]
/ Example: q bot.q :5001 :5002 :5003 -p 5004


/ Bot parameters
bank: 1000f; / How much USD we have in the bank
reserve: bank % 10; / We will not buy if bank < reserve
holdings: (`symbol$())!`float$(); / how much of each sym we're holding
botlogPrefix: `:botlog;
holdingslog: `:holdings;


if[not system"p";'"ERROR: please specify a port to listen on"];
if[3 <> count .z.x; '"ERROR: args should be TP, RDB & HDB handles"];
tp: `$":",.z.x 0;
rdb: `$":",.z.x 1;
hdb: `$":",.z.x 2;


/ get stats needed for vwap
getStats: {[t]
    select vwsp: sum size * price, volume: sum size by sym from t
 }

/ save the current bid and ask
getMarket: {[t]
    select last bid, last ask by sym from t
 }

/ update stats and market with tick data
upd: {[tab; newData]
    if[tab = `trades;
        stats:: stats pj getStats newData
    ];
    if[tab = `quotes;
        market:: market ^ getMarket newData
    ];
    trade[];
 }

/ calculate the vwap
calcVwap: {
    exec first vwsp % volume by sym from stats
 }

botTrades: ([] time: `timestamp$(); sym: `symbol$(); side: `symbol$(); price: `float$(); size: `float$());

trade: {
    vwap: calcVwap[];
    / we buy if the ask is less than the vwap
    buy: exec sym from market where vwap[sym] > (first; ask) fby sym;
    / else we sell (note we can never have ask < vwap < bid)
    sell: (exec sym from market) except buy;
    / we can only sell what we hold (no shorting)
    sell: sell inter where holdings > 0;
    if[count sell; execute[sell; `sell; holdings sell]];
    / execute buy trades, if we've got enough cash
    if[(bank > reserve) and 0 < count buy;
        usdPerSym: bank % 2 * count buy;
        sizes: usdPerSym % (exec first ask by sym from market) @ buy;
        execute[buy; `buy; sizes];
    ];
 }

/ buy/sell the given syms in given sizes
execute: {[syms; side; sizes]
    if[not side in `buy`sell; '"side must be one of: `buy`sell"];
    if[(count sizes) <> n: count syms; '"syms and sizes must be of the same length"];
    prices: (market each syms) @ $[side = `buy; `ask; `bid];
    logTrades (n#.z.p; syms; n#side; prices; sizes);
    adjustHoldings[syms; side; prices; sizes];
 }

/ adjust holdings & bank given purchase/sale of syms
adjustHoldings: {[syms; side; prices; sizes]
    bank +: $[side = `buy; -1; 1] * sum prices * sizes;
    holdings[syms] +: $[side = `buy; 1; -1] * sizes;
 }

/ write a trade to botlog and in memory table
logTrades: {[trades]
    `botTrades insert trades;
    botlogh enlist (`replayTrades; trades);
 }

replayTrades: {[trades]
    `botTrades insert trades;
    adjustHoldings[trades 1; first trades 2; trades 3; trades 4];
 }

.u.eod: {[today]
    / write our current holdings and bank to a file
    holdingslog set (holdings; bank);
    / write botTrades to disk and clear memory
    .Q.dpft[`:hdb; today; `sym; `botTrades];
    delete from `botTrades;
    / delete todays botlog
    hclose botlogh;
    hdel botlog;
    / begin a new day
    beginDay[];
    / tell hdb to reload
    h: hopen hdb;
    (neg h)"\\l .";
    hclose h;
 }

beginDay: {
    botlog:: `$ raze string (botlogPrefix; .z.d);
    if[not type key botlog;
        / if the botlog doesn't already exist, write an empty list
        .[botlog; (); :; ()]
    ];
    / replay the botlog (in case bot went down)
    -11! botlog;
    botlogh:: hopen botlog;
 }

init: {
    if[type key holdingslog;
        / if holdingslog exists, read it in
        tmp: get holdingslog;
        holdings:: tmp 0;
        bank:: tmp 1
    ];
    beginDay[];
    / get current world state from RDB
    rdbh: hopen rdb;
    stats:: rdbh(getStats; `trades);
    market:: rdbh(getMarket; `quotes);
    hclose rdbh;
    / subscribe to TP
    (hopen tp)(`.u.sub; `; `);
 }

status: {
    marketValue: exec first bid by sym from market where sym in key holdings;
    bank + sum marketValue * holdings
 }

init[];
