/ Usage: q bot.q [TP handle] [RDB handle] [HDB handle] -p [bot port]
/ Example: q bot.q :5001 :5002 :5003 -p 5004


/ How much USD we have in the bank
bank: 1000f;
/ We will not buy if bank < reserve
reserve: bank % 10;
/ How much BTC/ETH/... we're holding
holding: (`symbol$())!`float$();


if[not system"p";'"ERROR: please specify a port to listen on"];
if[3 <> count .z.x; '"ERROR: args should be TP, RDB & HDB handles"];
tp: hopen `$":",.z.x 0;
rdb: hopen `$":",.z.x 1;
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
    sell: sell inter where holding > 0;
    if[count sell; execute[sell; `sell; holding sell]];
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
    `botTrades insert (n#.z.p; syms; n#side; prices; sizes);
    bank +: $[side = `buy; -1; 1] * sum prices * sizes;
    holding[syms] +: $[side = `buy; 1; -1] * sizes;
 }

.u.eod: {[today]
    / close out all open positions
    execute[key holding; `sell; value holding];
    / write botTrades to disk and clear memory
    .Q.dpft[`:hdb; today; `sym; `botTrades];
    delete from `botTrades;
    / tell hdb to reload
    h: hopen hdb;
    h"\\l .";
    hclose h;
 }

/ on start, get current world state from RDB
stats: rdb(getStats; `trades);
market: rdb(getMarket; `quotes);

/ subscribe to TP
tp(`.u.sub; `; `);
/ keep connection open so can receive updates from TP
