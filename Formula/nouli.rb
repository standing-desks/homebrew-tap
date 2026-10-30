class Nouli < Formula
  desc "Multi-turn harness for decision models"
  homepage "https://standing-desks.github.io/nouli/"
  license "MIT"

  on_macos do
    depends_on arch: :arm64
  end

  if OS.mac?
    url "https://github.com/standing-desks/nouli/releases/download/v0.4.0/nouli-0.4.0-aarch64-apple-darwin.tar.gz"
    sha256 "6c1ae28667be1eaf67c2be6944d6838294da0ead84dac50d67d9efd6b6a5c0c6"
  elsif Hardware::CPU.arm?
    url "https://github.com/standing-desks/nouli/releases/download/v0.4.0/nouli-0.4.0-aarch64-unknown-linux-gnu.tar.gz"
    sha256 "146c8f58bc46f2c1b29aa447ffca2d10b7c1536c800a66dddc879b7e1159c7d2"
  else
    url "https://github.com/standing-desks/nouli/releases/download/v0.4.0/nouli-0.4.0-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "44bffa1e441f1bb231723bcecd0d1a3ac748175b938330b8b9bc6d4dfeb36f47"
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
