class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.9.0"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.9.0/openframe-companion-0.9.0-darwin-arm64.tar.gz"
    sha256 "33f62aa8386b17d85798406f39607e9a991077ee89e70043d7377a286653cd88"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.9.0/openframe-companion-0.9.0-darwin-amd64.tar.gz"
    sha256 "2e44f6bb1452cd7e29a3ff9b641cb0c23b4f232a19a70e6de00ce2ef9f6b6b15"
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
