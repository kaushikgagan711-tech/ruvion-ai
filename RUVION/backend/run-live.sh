#!/bin/zsh
# The provider key is stored in the macOS Keychain, never in the app bundle,
# JavaScript, or a launchd plist. The desktop client itself never sees it.
RUVION_GEMINI_KEY=$(/usr/bin/security find-generic-password -a ruvion-server -s RUVION.GEMINI_API_KEY -w 2>/dev/null)
RUVION_DIDIT_KEY=$(/usr/bin/security find-generic-password -a ruvion-server -s RUVION.DIDIT_API_KEY -w 2>/dev/null)
RUVION_DIDIT_WORKFLOW=$(/usr/bin/security find-generic-password -a ruvion-server -s RUVION.DIDIT_WORKFLOW_ID -w 2>/dev/null)
if [[ -z "$RUVION_GEMINI_KEY" ]]; then
  print -u2 "RUVION server key is unavailable in the macOS Keychain."
  exit 1
fi
exec /usr/bin/env GEMINI_API_KEY="$RUVION_GEMINI_KEY" DIDIT_API_KEY="$RUVION_DIDIT_KEY" DIDIT_WORKFLOW_ID="$RUVION_DIDIT_WORKFLOW" SSL_CERT_FILE=/etc/ssl/cert.pem RUVION_BIND=127.0.0.1 PORT=18766 \
  /Library/Frameworks/Python.framework/Versions/3.12/bin/python3 -u /Users/gagankaushik/Documents/Codex/2026-09-23/build-ruvion-as-a-real-native/RUVION/backend/server.py \
  >> /Users/gagankaushik/Documents/Codex/2026-09-23/build-ruvion-as-a-real-native/work/ruvion-api-daemon.log 2>&1
