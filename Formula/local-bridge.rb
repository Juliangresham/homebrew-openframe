class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.5.0"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.5.0/openframe-companion-0.5.0-darwin-arm64.tar.gz"
    sha256 "2a278c5ce98231a42624858b18c69ff4487cb354d4d73264611cb81b8cef7f46"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.5.0/openframe-companion-0.5.0-darwin-amd64.tar.gz"
    sha256 "5fbdc04029ae3d8a48ec66b46d60076d7c3009ef5282b9b0cd75b79c224c3e09"
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
