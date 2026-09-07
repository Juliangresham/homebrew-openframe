class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.6.8"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.6.8/openframe-companion-0.6.8-darwin-arm64.tar.gz"
    sha256 "f4871a6de92337acff32dfc17bac73d296bddc4db6d223622f1d0430ad5ed8ab"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.6.8/openframe-companion-0.6.8-darwin-amd64.tar.gz"
    sha256 "93dff4dc34a8005cb2ef2d81deb3241d316f7db2759f86fecc93f0c8016a5f4f"
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
