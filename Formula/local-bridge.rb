class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.6.4"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.6.4/openframe-companion-0.6.4-darwin-arm64.tar.gz"
    sha256 "5e8ae6ff451eaf6c47e5cfce2d711dcf923651740b23c775d155111ece32ff20"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.6.4/openframe-companion-0.6.4-darwin-amd64.tar.gz"
    sha256 "a0a80b5776f654439f133e8cc5bea477bcdec857cebb7209ee4ea1f98655dae9"
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
