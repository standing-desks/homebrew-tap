# Standing Desks Homebrew tap

Homebrew packages for [Nouli](https://github.com/standing-desks/nouli) and [Handshake](https://github.com/standing-desks/handshake). The repository is `standing-desks/homebrew-tap`, addressed by Homebrew as `standing-desks/tap`.

## Nouli

Nouli is a multi-turn decision harness. The formula installs the published executable for Apple silicon macOS or ARM64 GNU/Linux. Linux requires system glibc 2.38 or newer; the release is tested on Ubuntu 24.04. Rust and provider credentials are not needed to install it.

```sh
brew install standing-desks/tap/nouli
nouli --version
```

To update:

```sh
brew update
brew upgrade standing-desks/tap/nouli
```

To uninstall:

```sh
brew uninstall standing-desks/tap/nouli
```

Uninstalling preserves configuration and saved sessions in `~/.nouli` or a custom store. Follow the [Nouli user guide](https://standing-desks.github.io/nouli/guide/) to configure a provider.

If you installed with Cargo, run `cargo uninstall nouli-cli` before switching to Homebrew. Remove any manually installed executable from your PATH too, so it does not shadow the Homebrew installation.

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

PR checks select packages by changed files. They validate and install Handshake only when cask or shared tooling changes, and Nouli only when its formula or shared tooling changes. README-only changes skip package installations. Nouli is tested on macOS ARM64 and Ubuntu 24.04 ARM64. The required **Tap validation** check waits for all selected checks.

Run Homebrew installation checks in CI or a disposable Homebrew installation. Keep development validation separate from your installed tap. `make link-tap` registers this checkout locally and refuses to replace an existing registration pointing elsewhere.

For a disposable installation, the Nouli checks are:

```sh
make link-tap
brew trust --formula standing-desks/tap/nouli
brew style Formula/nouli.rb
brew audit --formula standing-desks/tap/nouli
brew install --formula standing-desks/tap/nouli
brew test standing-desks/tap/nouli
brew uninstall --formula standing-desks/tap/nouli
```

Handshake's `make check`, `make audit-online`, and `make install-smoke` retain its cask validation and signed-app installation checks. Its smoke check uses a temporary application directory, does not launch the app, and refuses to run if the cask is already installed.

## Release updates

Authenticate GitHub CLI, then select the package:

```sh
make update                     # Handshake
make update PACKAGE=nouli       # Nouli
make update PACKAGE=nouli RELEASE_TAG=v0.1.0
```

The updater selects a published stable release, verifies each downloaded archive against its published checksums, and updates the package definition. It rejects incomplete releases and leaves the package unchanged for the same or an older version. Handshake uses `SHA256SUMS`; Nouli uses a `.sha256` sidecar for each platform archive.

The **Update release packages** workflow receives `handshake-release-published`, legacy `twine-release-published`, and `nouli-release-published` dispatches. A manual run can select a package and release tag, or use its latest stable release. There is no timed schedule.

The updater runs on Linux, opens a package-specific PR, waits for **Tap validation**, and squash-merges that exact bot commit. Installation checks run in the PR, once per selected package/platform. Each automated PR may change only its selected package file. Nouli updates are restricted to this Standing Desks tap; Handshake also supports the compatibility tap.

The tap needs the existing `TAP_APP_CLIENT_ID` repository variable and `TAP_APP_PRIVATE_KEY` Actions secret. The App requires Contents and Pull requests read/write access to this tap. Source repositories use the same App to dispatch release notifications, with Contents write access to the tap. In Nouli, configure these names in Settings > Secrets and variables > Actions. Private keys belong in Actions secrets, never repository files.

Only the maintainers and update App can merge to `main`, through PRs with passing checks. Human approval is not required for the bot's verified release updates. Users receive packaged updates when they run `brew upgrade`.
