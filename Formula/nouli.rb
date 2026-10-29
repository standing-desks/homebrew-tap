class Nouli < Formula
  desc "Multi-turn harness for decision models"
  homepage "https://standing-desks.github.io/nouli/"
  license "MIT"

  depends_on arch: :arm64

  if OS.mac?
    url "https://github.com/standing-desks/nouli/releases/download/v0.2.0/nouli-0.2.0-aarch64-apple-darwin.tar.gz"
    sha256 "51c854887db8951e3f75a6e9f428f1908a3e0e99a6e91660eef94ad8dc82d87c"
  elsif OS.linux?
    url "https://github.com/standing-desks/nouli/releases/download/v0.2.0/nouli-0.2.0-aarch64-unknown-linux-gnu.tar.gz"
    sha256 "44c6c3f9bf9611f13111ef058cbc2d07d995ce7d3b33a1ca5eae9f246e6cd915"
  end

  def install
    if OS.linux? && OS::Linux::Glibc.system_version < Version.new("2.38")
      odie "Nouli requires system glibc 2.38 or newer; use Ubuntu 24.04 or a compatible GNU/Linux system"
    end
    bin.install "nouli"
  end

  test do
    assert_equal "nouli 0.1.0", shell_output("#{bin}/nouli --version").strip
    assert_match "Usage: nouli", shell_output("#{bin}/nouli --help")
    refute_path_exists testpath/".nouli"
  end
end
