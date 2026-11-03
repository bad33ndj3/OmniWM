# Personal WM repository

- For Personal WM checks, builds, post-feature restart, or macOS interaction validation, use [`personal-wm-test`](.agents/skills/personal-wm-test/SKILL.md).
- Read [`HANDOFF.md`](HANDOFF.md) before app activation or changes involving the active WM.
- Use `Scripts/build-personal-wm-dev.sh` for integrated development builds. It signs with the existing `LocalDevCert`; retain that certificate and private key across rebuilds to preserve the TCC identity. See [signing details](docs/personal-wm/native-integration.md#vaste-ontwikkelrechten).
