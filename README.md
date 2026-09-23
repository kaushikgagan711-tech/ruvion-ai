# RUVION

Native macOS RUVION desktop app with a bundled WKWebView UI and a server-side Gemini API.

## macOS download

Download `RUVION.app` from the release or repository files, move it to Applications or Desktop, and open it. The app never asks end users for a Gemini API key.

## Build on macOS

```sh
/bin/zsh RUVION/build.sh
open RUVION/build/RUVION.app
```

The current release gives every profile a server-tracked six-month Pro trial, including Plus features. Payment is optional after the trial; no student verification is required for this universal trial.

## Windows

This repository currently contains the native macOS target. A Windows package requires a separate Windows/Tauri port and must be built on a Windows runner; no Windows binary is claimed by this repository yet.

## Security

Provider keys belong only on the server. Do not commit API keys, database files, or runtime logs.
