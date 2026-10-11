class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.15.0"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.15.0/openframe-companion-0.15.0-darwin-arm64.tar.gz"
    sha256 "a5a33ad00f5995022981d7d2fae41ec9398bf0db9e25c5461077eda68cec446f"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.15.0/openframe-companion-0.15.0-darwin-amd64.tar.gz"
    sha256 "601a6f1b47a3d8cc376a59e7ca3ac261ec0c4e682016747d0843a2bd09151084"
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
