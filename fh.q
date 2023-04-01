/ Usage: q fh.q [TP handle] -p [FH port]
/ Example: q fh.q :5001 -p 5000


if[not system"p";'"ERROR: please specify a port to listen on"];
if[1 <> count .z.x; '"ERROR: arg should be TP handle"];
tp: hopen `$":", .z.x 0;


parseTrades: {[trades]
    syms: "S"$ trades[;`symbol];
    sides: ?[trades[;`makerSide] ~\: "bid"; `sell; `buy];
    prices: "F"$ trades[; `price];
    sizes: "F"$ trades[; `amount];
    flip `sym`side`price`size!(syms; sides; prices; sizes)
 }

parseQuotes: {[quotes]
    syms: "S"$ quotes[;`symbol];
    n: count quotes;
    bidIxs: where quotes[;`side] ~\: "bid";
    askIxs: (til n) except bidIxs;
    bids: n#0Nf;
    asks: n#0Nf;
    bsizes: n#0Nf;
    asizes: n#0Nf;
    bids[bidIxs]: "F"$ quotes[bidIxs; `price];
    bsizes[bidIxs]: "F"$ quotes[bidIxs; `remaining];
    asks[askIxs]: "F"$ quotes[askIxs; `price];
    asizes[askIxs]: "F"$ quotes[askIxs; `remaining];
    quotes: flip `sym`bid`ask`bsize`asize!(syms; bids; asks; bsizes; asizes);
    lastNonNull: ('[last; fills]);
    0! select lastNonNull bid, lastNonNull ask, lastNonNull bsize, lastNonNull asize by sym from quotes
 }

.z.ws: {
    x: .j.k x;
    if[not "update" ~ x`type; 0N! "Received bad msg: ", .Q.s1 x; :`];
    / timestampms is the no. of ms since 1970.01.01 UTC
    time: $[`timestampms in key x;
        `timestamp$ 1000000 * (`long$ x`timestampms) - 946684800000;
        .z.p
    ];
    events: x`events;
    tradeIxs: where (events[;`type]) ~\: "trade";
    trades: parseTrades events tradeIxs;
    if[n: count trades; (neg tp)(`.u.upd; `trades; update time: n#time from trades)];
    quotes: parseQuotes events (til count events) except tradeIxs;
    if[n: count quotes; (neg tp)(`.u.upd; `quotes; update time: n#time from quotes)];
 }

syms: `btcusd`ethusd`ltcusd`dogeusd
(`$":ws://localhost:80")"GET /v1/multimarketdata?top_of_book=true&bids=true&offers=true&trades=true&symbols=", sv[",";string syms], " HTTP/1.1\r\nHost: api.gemini.com\r\n\r\n";
