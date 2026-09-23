class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.8.1"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.8.1/openframe-companion-0.8.1-darwin-arm64.tar.gz"
    sha256 "0b5af57c7c9ac68a9312c596b2656595fcd0a5f9bbcf9ffe44aea156d97d5db2"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.8.1/openframe-companion-0.8.1-darwin-amd64.tar.gz"
    sha256 "4b6000d9da94866278fedda699ce4d3c1f55152525536ecaf498c221ba4b84b2"
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
