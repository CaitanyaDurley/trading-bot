/ websocket open handler x = handle
.z.wo: {0N! "WS opened: ", string x}
/ websocket close handler x = handle
.z.wc: {0N! "WS closed: ", string x}
/ websocket message handler x = msg
.z.ws: {neg[.z.w] 0N! .Q.s value x}

/ .j.j parses q into a json string
t: ([col1: `a`b`c] col2: 1 2 3) / no distinction between keyed/unkeyed tables
.j.j t

/ .j.k parses json string into q
.j.k .j.j t / note col1 has type of string


.z.ws: {neg[.z.w] 0N! .j.j value x}

