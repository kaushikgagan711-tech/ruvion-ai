# RUVION native macOS app

This directory contains the native AppKit/WKWebView host and the premium RUVION interface it loads locally. The app does not open a browser or authentication page.

## Build

Run `./build.sh` on a Mac after accepting the locally installed Xcode license. It produces `RUVION.app`; copy that bundle to the Desktop to install it.

The host persists its local profile at `~/Library/Application Support/RUVION/profile.json` and connects to the guarded local RUVION service during development. A hosted release can replace that address with a deployed HTTPS endpoint. Provider secrets are never part of the app bundle.

## Backend

`backend/` is the server-side Gemini/Razorpay implementation. Deploy it behind HTTPS with the supplied environment variables. Until it is deployed and has valid credentials, chat displays a clear configuration error and payments display `Payments aren't configured yet.`
