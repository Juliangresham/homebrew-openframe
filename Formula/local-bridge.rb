class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.17.0"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.17.0/openframe-companion-0.17.0-darwin-arm64.tar.gz"
    sha256 "014193329d6dafc97ebee1fb99e9b17ef9f87ff2a80485fd43604463fa82f37c"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.17.0/openframe-companion-0.17.0-darwin-amd64.tar.gz"
    sha256 "3e689a1b77a9ab7c7fa70677bf68b42ec353c9ee45fca1229f885c07295fae1e"
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
