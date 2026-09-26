# Windows packaging

This repository owns one small shared Inno Setup wrapper for Captain's Windows applications.

Rules:

- Inno Setup owns Windows installer behavior. Do not reimplement installation, update, uninstall, registry bookkeeping, or wizard UI.
- Product repositories own their staged runtime files and application behavior.
- Keep one generic `app.iss` plus the smallest wrapper needed to invoke `ISCC.exe`.
- Same `AppId` means the same installed application across versions.
- Default to per-user installs below `%LOCALAPPDATA%\Programs`; no UAC.
- Do not add runtime downloaders, manifests, provider integrations, package feeds, services, hooks, or product-specific logic unless a demonstrated requirement earns them.
- Test changes on the accepted Win11 VM with a real application bundle before promotion.
