from websocket import WebSocketApp

def on_message(ws, msg):
    print(msg)

def on_error(ws, err):
    print(err)

def on_close(ws):
    print("ws closed")

def on_open(ws):
    print("ws open")

ws = WebSocketApp("ws://localhost:4242",
               on_message=on_message,
               on_error=on_error,
               on_close=on_close,
               on_open=on_open
    )

ws.send("1+1")
ws.send("2*1+3")
ws.close()
# finnhub = trades only for us stocks
# gemini = trades & quotes (level 2!) only for crypto