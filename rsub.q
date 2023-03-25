/
Library of common functions used by realtime subscribers
The TP itself uses this library
globals used:
    .u.t - table names as symbols
    .u.w - dictionary of (table name from .u.t)!(list of (handle to subscriber; chosen syms))
\

/ set namespace to .u
\d .u

/ set .u.t and initialise .u.w
init: {
    t:: tables `.;
    w:: t!(count t)#()
 }

/ delete a downstream subscriber from .u.w
del: {[tab; handle]
    w[tab]_: w[tab;;0]?handle
 }
/ when a downstream subscriber disconnects, stop sending them updates
.z.pc: {del[;x] each t};

/ select data from a table (not a table name) for a (list of) sym(s)
sel: {[tab; syms]
    $[`~syms; tab; select from tab where sym in syms]
 }

/ publish an update for tab to any subscribers
pub: {[tab; newData]
    {
        filteredUpdate: sel[newData; x 1];
        if[count filteredUpdate; (neg x 0)(`upd; tab; filteredUpdate)];
    } each w tab
 }

/ INTERNAL FUNCTION ONLY
/ add a downstream subscriber to .u.w
/ or update their subscribed syms if already subscribed
add: {[tab; syms]
    i: w[tab;;0]?.z.w;
    $[
        (count w tab) > i; / is this client already subscribed
        .[`.u.w; (x; i; 1); union; syms]; / if so add any new requested syms
        w[x],: enlist (.z.w; y); / if not add them to .u.w
    ];
    / return the (new) schema, with grouped attr on sym col
    (tab; @[0 # value tab; `sym; `g#])
 }

/ external function to subscribe to a/all tables
sub: {[tab; syms]
    if[tab~`; :sub[; syms] each t];
    if[not tab in t;'tab];
    del[tab; .z.w];
    add[tab; syms]
 }


end: {[today]
    (neg (union/) w[;;0]) @\: (`.u.end; today)
 }
