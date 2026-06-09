#!/bin/bash
# Connect to Brave DevTools and click the noVNC connect button

ws_url="ws://localhost:9222/devtools/page/86A0DB96CB88504305A0B43F7E07A112"

click_cmd='{"id":1,"method":"Runtime.evaluate","params":{"expression":"document.querySelector('"'"'#noVNC_connect_button'"'"')?.click() || '"'"'no button'"'"'"}}'
screenshot_cmd='{"id":2,"method":"Runtime.evaluate","params":{"expression":"document.body.innerHTML.length"}}'

echo "Sending click command..."
echo "$click_cmd" | websocat "$ws_url" 2>&1 | head -5

echo ""
echo "Sending screenshot size check..."
echo "$screenshot_cmd" | websocat "$ws_url" 2>&1 | head -5
