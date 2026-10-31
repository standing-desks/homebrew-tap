class Nouli < Formula
  desc "Multi-turn harness for decision models"
  homepage "https://standing-desks.github.io/nouli/"
  license "MIT"

  on_macos do
    depends_on arch: :arm64
  end

  if OS.mac?
    url "https://github.com/standing-desks/nouli/releases/download/v0.4.1/nouli-0.4.1-aarch64-apple-darwin.tar.gz"
    sha256 "e962665e83dbbcd8b68b021d41995b273e0049c3ff0881c0aa8cbe70df2860fd"
  elsif Hardware::CPU.arm?
    url "https://github.com/standing-desks/nouli/releases/download/v0.4.1/nouli-0.4.1-aarch64-unknown-linux-gnu.tar.gz"
    sha256 "54eed1bae7421f0766593695781858341cff0c33e03f9dc291ff5b3f1d089ccc"
  else
    url "https://github.com/standing-desks/nouli/releases/download/v0.4.1/nouli-0.4.1-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "f989f5e276eebcc6e3af78375ed2e9b4d00b9d04fbfbbcb9754f7fdaa75e0854"
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
