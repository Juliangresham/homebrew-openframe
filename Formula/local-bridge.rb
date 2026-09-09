class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.7.0"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.7.0/openframe-companion-0.7.0-darwin-arm64.tar.gz"
    sha256 "9a0c262e70dcfe92feaa23c8683f05cc0267419f7d603181eba2d3cca10c18bd"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.7.0/openframe-companion-0.7.0-darwin-amd64.tar.gz"
    sha256 "d590219f824faf8a4a87485ad514fb2b46ab3491adf4c97043cbb36cb4ea50ec"
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
