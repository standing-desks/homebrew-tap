class Nouli < Formula
  desc "Multi-turn harness for decision models"
  homepage "https://standing-desks.github.io/nouli/"
  license "MIT"

  on_macos do
    depends_on arch: :arm64
  end

  if OS.mac?
    url "https://github.com/standing-desks/nouli/releases/download/v0.4.2/nouli-0.4.2-aarch64-apple-darwin.tar.gz"
    sha256 "426659ba108a3d338d45a9de21cf9da5efae5089fbcc1bb32469ce867a79ccdb"
  elsif Hardware::CPU.arm?
    url "https://github.com/standing-desks/nouli/releases/download/v0.4.2/nouli-0.4.2-aarch64-unknown-linux-gnu.tar.gz"
    sha256 "def2f1aacc00a82dda50cad011bc32ce25e0e034a50f4bfafca9922c1f362759"
  else
    url "https://github.com/standing-desks/nouli/releases/download/v0.4.2/nouli-0.4.2-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "d3ffad4e46374b53a79553fff309419e905e0012afa7887d38903c4f1d7847d3"
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
