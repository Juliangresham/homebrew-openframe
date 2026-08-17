class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.4.7"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.4.7/openframe-companion-0.4.7-darwin-arm64.tar.gz"
    sha256 "eab691b98de8fff1a3f0250f5e0a1f93d88bd2675067f93149363d0da0f21435"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.4.7/openframe-companion-0.4.7-darwin-amd64.tar.gz"
    sha256 "0ee8cd0e00cdf88ce73105ea4d0e7987214ec965cf8422abed7acb43852830ff"
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
