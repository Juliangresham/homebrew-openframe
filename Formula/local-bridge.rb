class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://openframe.juliangresham.com"
  version "0.1.0"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.1.0/openframe-companion-0.1.0-darwin-arm64.tar.gz"
    sha256 "75a7da29743e16c258dc54fe5c04b250b647af790216e3517690feee67ab4900"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.1.0/openframe-companion-0.1.0-darwin-amd64.tar.gz"
    sha256 "8ed11e3f32374b80adfbff8919bc6c102d5de6a22d8083ff624ec21f618ddbc3"
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
