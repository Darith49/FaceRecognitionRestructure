#!/usr/bin/env bash
fuser -k 8080/tcp 2>/dev/null && echo "Stopped server on port 8080" || echo "No server running on port 8080"
