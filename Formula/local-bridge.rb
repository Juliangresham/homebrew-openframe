class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.12.0"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.12.0/openframe-companion-0.12.0-darwin-arm64.tar.gz"
    sha256 "816c18f59c83a961e0db9ba76185bb6814ed2d9d4cc5483ba409f1b25f7df5d2"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.12.0/openframe-companion-0.12.0-darwin-amd64.tar.gz"
    sha256 "a2a2e059a4cf7f9011d2425ba84ca97e6c79fc68613de8440fd62d8b8f23d0dc"
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
