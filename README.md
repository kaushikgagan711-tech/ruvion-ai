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

The `windows/` folder contains a native WinForms/WebView2 shell that reuses the RUVION UI. Install the .NET 8 SDK and WebView2 Runtime, then run:

```powershell
dotnet publish windows/RUVION.Windows.csproj -c Release -r win-x64 --self-contained true -o windows/publish
```

GitHub Actions also builds `RUVION-Windows-x64.zip` automatically. Open **Actions → Build RUVION for Windows → the latest successful run → Artifacts** on another computer and download that ZIP.

## Security

Provider keys belong only on the server. Do not commit API keys, database files, or runtime logs.
