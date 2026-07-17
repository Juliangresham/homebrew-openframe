class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.3.1"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.3.1/openframe-companion-0.3.1-darwin-arm64.tar.gz"
    sha256 "7335dc9d8e178b97af539c0c65aaed45343df362fa070acddd3cb20265aaa299"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.3.1/openframe-companion-0.3.1-darwin-amd64.tar.gz"
    sha256 "36347f6d97b0a0559637b123a0eb8c7afe46b628ab8f08c247f59c656b35b1d5"
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
