# RUVION for Windows

This is the Windows-native shell for RUVION. It opens the existing RUVION UI in a native WinForms window using Microsoft Edge WebView2; it does not open a browser tab and it never asks users for a Gemini API key.

## Build on Windows

1. Install the .NET 8 SDK and the Microsoft Edge WebView2 Runtime.
2. Open PowerShell in this `windows` folder.
3. Run:

```powershell
dotnet restore
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=false -o publish
```

The executable is `publish\RUVION.exe`. The GitHub Actions workflow in `.github/workflows/windows.yml` runs this build on a Windows runner and publishes a downloadable artifact for each run.

The AI service remains server-side. Configure the guarded RUVION backend endpoint for a hosted release; do not put Gemini, Razorpay, or other provider secrets in this app.
