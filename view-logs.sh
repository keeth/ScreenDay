#!/bin/bash

echo "=== ScreenDay Logs ==="
echo "Watching for ScreenDay log messages..."
echo ""

# Follow Console logs for ScreenDay app
log stream --predicate 'subsystem == "io.vurt.ScreenDay"' --style compact
