class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.3.9"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.3.9/openframe-companion-0.3.9-darwin-arm64.tar.gz"
    sha256 "702d6aa868a11a21fa6d1e2f584cf1a6ddaeb8b0c19cf0de279e75828421c292"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.3.9/openframe-companion-0.3.9-darwin-amd64.tar.gz"
    sha256 "fd4618b0adf11386f964b16d7547cf542a13f7674eebebc3ab7a7669b20d6c23"
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
