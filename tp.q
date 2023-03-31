/
Usage: q tp.q [schema.q file] [prefix for tplog] -p [TP port]
Example: q tp.q schema.q tplog -p 5001
globals used:
    .u.L - tplog hsym, e.g. `:tplog2008.09.11
    .u.l - handle to tp log file
    .u.d - today's date (UTC)
\

if[not system"p";'"ERROR: please specify a port to listen on"];
if[2 <> count .z.x; '"ERROR: args should be schema.q & tplog prefix"];

/ load schema
system "l ", .z.x 0

/ load realtime publisher library
\l rpub.q
/ set namespace to .u
\d .u

/ open a handle to tplog
openTPlog: {[today]
    L:: `$(-10_string L), string today;
    if[not type key L;
        / if the tplog doesn't already exist, write an empty list
        .[L;();:;()]
    ];
    / replay the tplog (in case TP went down)
    i: -11!(-2; L);
    / if there was a bad entry, -11! returns (blah; length of valid part)
    if[0 <= type i;
        -2 (string L),"  is a corrupt log. Truncate to length ", (string last i), " and restart";
        exit 1
    ];
    hopen L
 }

/ init tables, set template .u.L, set .u.d and call .u.openTPlog
tick: {[tplogPrefix]
    init[]; / call .u.init from rpub library
    if[
        any not (`time`sym ~ 2 # cols value @) each t;
        '"Schema has a table whose first 2 columns are not `time`sym"
    ];
    L:: `$":", tplogPrefix, 10#".";
    d:: .z.d;
    l:: openTPlog d;
 }

/ function to be called at eod
eod: {
    end d; / call .u.end from rpub
    if[l; hclose l];
    hdel L;
    d+: 1;
    -1 "Beginning new day: ", string d;
    l:: openTPlog d; / open new tplog handle
 }

/ check if we've passed into tomorrow
ts: {[today]
    if[d < today;
        eod[];
    ]
 };

.z.ts: {
    / push any updates received since last .z.ts call
    t pub' value each t;
    / reset the tables
    @[`.; t; @[; `sym; `g#] 0 #];
    ts .z.d;
 };

/ function called by FH
upd:{[t;x]
    t insert x;
    if[l; l enlist (`upd; t; x)];
 };

/ default to 1ms updates
if[not system"t"; system"t 1"];


\d .
.u.tick .z.x 1;
