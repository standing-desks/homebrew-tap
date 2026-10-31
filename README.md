# Standing Desks Homebrew tap

Homebrew package for [Handshake](https://github.com/standing-desks/handshake). The repository is `standing-desks/homebrew-tap`, addressed by Homebrew as `standing-desks/tap`.

Nouli moved to [`nouli-ai/tap`](https://github.com/nouli-ai/homebrew-tap). `tap_migrations.json` moves existing `standing-desks/tap/nouli` installations there on the next `brew update`; install it with `brew install nouli-ai/tap/nouli`.

## Handshake

Handshake is a native macOS workspace for coordinating coding agents. It requires macOS 26 or later. The cask is `handshake`; legacy `twine-app` and `twine-ade` tokens map to it. ARM64 packages require Apple silicon; universal packages also support Intel.

```sh
brew install --cask standing-desks/tap/handshake
```

To update:

```sh
# Once when migrating from twine-app or twine-ade on Homebrew 6 or newer:
brew trust --cask standing-desks/tap/handshake
brew update
brew upgrade --cask standing-desks/tap/handshake
```

[Tap trust](https://docs.brew.sh/Tap-Trust) does not follow a cask rename. Omit the trust command on older Homebrew versions. Existing `twineproject/tap` users can use `twineproject/tap/handshake` without switching taps or installing another copy.

To uninstall:

```sh
brew uninstall --cask standing-desks/tap/handshake
```

Uninstalling preserves saved sessions, workflows, transcripts, and settings. If you installed by dragging the app into Applications, move the existing app out before the first Homebrew installation. Quit Handshake before upgrading.

The cask installs the published, Developer ID signed and notarized DMG. Homebrew verifies its checksum. See [Handshake's installation notes](https://standing-desks.github.io/handshake/documentation/guide/#install).

## Validate changes

Run the updater tests and lint tools from this checkout:

```sh
make test
actionlint
shellcheck scripts/*.sh
```

PR checks validate and install Handshake only when cask or shared tooling changes. README-only changes skip package installations. The required **Tap validation** check waits for all selected checks.

Run Homebrew installation checks in CI or a disposable Homebrew installation. Keep development validation separate from your installed tap. `make link-tap` registers this checkout locally and refuses to replace an existing registration pointing elsewhere.

Handshake's `make check`, `make audit-online`, and `make install-smoke` retain its cask validation and signed-app installation checks. Its smoke check uses a temporary application directory, does not launch the app, and refuses to run if the cask is already installed.

## Release updates

Authenticate GitHub CLI, then run:

```sh
make update
make update RELEASE_TAG=v0.7.0
```

The updater selects a published stable release, verifies each downloaded archive against its published checksums, and updates the cask. It rejects incomplete releases and leaves the cask unchanged for the same or an older version. Archives are verified against `SHA256SUMS`.

The **Update release packages** workflow receives `handshake-release-published` and legacy `twine-release-published` dispatches. A manual run can select a release tag, or use the latest stable release. There is no timed schedule.

The updater runs on Linux, opens a cask PR, waits for **Tap validation**, and squash-merges that exact bot commit. Installation checks run in the PR. Each automated PR may change only the cask file. Handshake also supports the compatibility tap.

The tap needs the existing `TAP_APP_CLIENT_ID` repository variable and `TAP_APP_PRIVATE_KEY` Actions secret. The App requires Contents and Pull requests read/write access to this tap. Source repositories use the same App to dispatch release notifications, with Contents write access to the tap. In Handshake, configure these names in Settings > Secrets and variables > Actions. Private keys belong in Actions secrets, never repository files.

Only the maintainers and update App can merge to `main`, through PRs with passing checks. Human approval is not required for the bot's verified release updates. Users receive packaged updates when they run `brew upgrade`.
