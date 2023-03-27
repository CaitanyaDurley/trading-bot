from websocket import create_connection

ws = create_connection("wss://api.gemini.com:443/v1/multimarketdata?symbols=BTCUSD,ETHUSD")
# ws = create_connection("ws://localhost/v1/multimarketdata?symbols=BTCUSD,ETHUSD")
print(ws.recv())
ws.close()