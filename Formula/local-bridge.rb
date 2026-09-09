class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.7.1"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.7.1/openframe-companion-0.7.1-darwin-arm64.tar.gz"
    sha256 "940cb39f042170ed742cdea08afeba154d9027690719cf576156882614f056b7"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.7.1/openframe-companion-0.7.1-darwin-amd64.tar.gz"
    sha256 "d066654f2010738ecc6185e4d37346db1099092ab09ace0d1ee917cda10aa92a"
  end

  def install
    bin.install "openframe-companion"
    # Re-apply the ad-hoc signature last, so it survives Homebrew's relocation.
    system "codesign", "-s", "-", "--force", bin/"openframe-companion"
  end

  service do
    run [opt_bin/"openframe-companion"]
    keep_alive true
    run_at_load true
    log_path var/"log/openframe-companion.log"
    error_log_path var/"log/openframe-companion.log"
  end

  test do
    assert_match "Usage", shell_output("#{bin}/openframe-companion help")
  end
end
