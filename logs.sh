#!/bin/bash

echo "📋 Streaming ScreenDay logs..."
echo "Press Ctrl+C to stop"
echo ""

# Stream all log levels (info, debug, error) for ScreenDay
log stream \
  --predicate 'subsystem == "io.vurt.ScreenDay"' \
  --level debug \
  --style compact \
  --color auto
