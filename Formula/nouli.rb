class Nouli < Formula
  desc "Multi-turn harness for decision models"
  homepage "https://standing-desks.github.io/nouli/"
  license "MIT"

  on_macos do
    depends_on arch: :arm64
  end

  if OS.mac?
    url "https://github.com/standing-desks/nouli/releases/download/v0.3.0/nouli-0.3.0-aarch64-apple-darwin.tar.gz"
    sha256 "05ba1aa8f007f6008c5fd1ec4ef9cb0917b5b0540fcf3cf3a3df1adb7c60e4a2"
  elsif Hardware::CPU.arm?
    url "https://github.com/standing-desks/nouli/releases/download/v0.3.0/nouli-0.3.0-aarch64-unknown-linux-gnu.tar.gz"
    sha256 "7a79d58963e9634ff82aa51a6aae3eab2fc2e18829688b54d37e1338d3d4bcea"
  else
    url "https://github.com/standing-desks/nouli/releases/download/v0.3.0/nouli-0.3.0-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "806592007e1255fc94f417c8036cdc7adf5018e03554067b1fc431c3c4d89dfa"
  end

  def install
    if OS.linux? && OS::Linux::Glibc.system_version < Version.new("2.38")
      odie "Nouli requires system glibc 2.38 or newer; use Ubuntu 24.04 or a compatible GNU/Linux system"
    end
    bin.install "nouli"
  end

  test do
    assert_equal "nouli #{version}", shell_output("#{bin}/nouli --version").strip
    assert_match "Usage: nouli", shell_output("#{bin}/nouli --help")
    refute_path_exists testpath/".nouli"
  end
end
