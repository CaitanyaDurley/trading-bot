/ Usage: q bot.q [TP handle] [RDB handle] -p [bot port]
/ Example: q bot.q host:port :port -p 5004


/ How much USD we have in the bank
bank: 100f;
/ How much BTC/ETH/... we're holding
holding: (`symbol$())!`float$();

if[not system"p";'"ERROR: please specify a port to listen on"];
if[2 <> count .z.x; '"ERROR: args should be TP & RDB handles"];
tp: hopen `$":",.z.x 0;
rdb: hopen `$":",.z.x 1;


/ get stats needed for vwap
getStats: {[t]
    select vwsp: sum size * price, volume: sum size by sym from t
 }

/ save the current bid and ask
getMarket: {[t]
    select last bid, last ask by sym from t
 }

/ on start, get current world state from RDB
stats: rdb(getStats; `trades);
market: rdb(getMarket; `quotes);

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

trades: ([] time: `timestamp$(); sym: `symbol$(); side: `symbol$(); size: `float$());

trade: {
    vwap: calcVwap[];
    / we buy if the ask is less than the vwap
    buy: exec sym from market where vwap[sym] > (first; ask) fby sym;
    / else we sell (note we can never have ask < vwap < bid)
    sell: (exec sym from market) except buy;
    / we can only sell what we hold (no shorting)
    sell: sell inter key holding;
    / execute sell trades
    if[n: count sell;
        `trades insert (n#.z.p; sell; n#`sell; holding[sell]);
        bank +: sum (holding * exec first bid by sym from market) @ sell;
        holding[sell]: 0f
    ];
    / execute buy trades, if we've got > 1USD
    if[(bank > 1) and 0 <n: count buy;
        usdPerSym: (bank %: 2) % n;
        sizes: usdPerSym % (exec first ask by sym from market) @ buy;
        `trades insert (n#.z.p; buy; n#`buy; sizes);
        holding[buy] +: sizes
    ];
 }

/ subscribe to TP
tp(`.u.sub; `; `);
/ keep connection open so can receive updates from TP
