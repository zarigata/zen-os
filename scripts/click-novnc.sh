#!/bin/bash
# Connect to Brave DevTools and click the noVNC connect button

ws_url="ws://localhost:9222/devtools/page/$(curl -s http://localhost:9222/json | python3 -c 'import sys,json; pages=json.load(sys.stdin); print(pages[0]["id"]) if pages else sys.exit(1)')"

click_cmd='{"id":1,"method":"Runtime.evaluate","params":{"expression":"document.querySelector('"'"'#noVNC_connect_button'"'"')?.click() || '"'"'no button'"'"'"}}'
screenshot_cmd='{"id":2,"method":"Runtime.evaluate","params":{"expression":"document.body.innerHTML.length"}}'

echo "Sending click command..."
echo "$click_cmd" | websocat "$ws_url" 2>&1 | head -5

echo ""
echo "Sending screenshot size check..."
echo "$screenshot_cmd" | websocat "$ws_url" 2>&1 | head -5
