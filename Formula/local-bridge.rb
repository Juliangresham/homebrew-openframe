class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.13.0"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.13.0/openframe-companion-0.13.0-darwin-arm64.tar.gz"
    sha256 "50e73aae0dcf69347a33db97e1753f5c9c227d643932bbadada1214c98fc6ae1"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.13.0/openframe-companion-0.13.0-darwin-amd64.tar.gz"
    sha256 "02d8d688475f09f8eb95d51b1e3b8359652349fac03de8cafee94b9e442972f0"
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
