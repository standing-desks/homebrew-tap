cask "handshake" do
  version "0.8.0"
  sha256 "3be7fc7086318e050062a4b0b5ce31429f4b3b4776791b70b9aadcc914151a69"

  url "https://github.com/standing-desks/handshake/releases/download/v#{version}/Handshake-#{version}-macos-arm64.dmg"
  name "Handshake"
  desc "Agent development environment for coordinating coding agents"
  homepage "https://standing-desks.github.io/handshake/"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :tahoe

  app "Handshake.app"

  # Handshake's saved sessions, transcripts, and workflows are user data.
  # No zap stanza required.
end
