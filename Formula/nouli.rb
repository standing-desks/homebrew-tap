class Nouli < Formula
  desc "Multi-turn harness for decision models"
  homepage "https://standing-desks.github.io/nouli/"
  license "MIT"

  depends_on arch: :arm64

  if OS.mac?
    url "https://github.com/standing-desks/nouli/releases/download/v0.1.0/nouli-0.1.0-aarch64-apple-darwin.tar.gz"
    sha256 "014decbff5ac82ba4f390acbdc892d328e8fc9ac59704640629f27944f266611"
  elsif OS.linux?
    url "https://github.com/standing-desks/nouli/releases/download/v0.1.0/nouli-0.1.0-aarch64-unknown-linux-gnu.tar.gz"
    sha256 "1f10e0000182a31be71db88f12f3ef11b6b7fb68f40bc5283554688bb8772d31"
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
