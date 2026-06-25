class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://openframe.juliangresham.com"
  version "0.1.1"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.1.1/openframe-companion-0.1.1-darwin-arm64.tar.gz"
    sha256 "e8156ce94c1169c2697a585001d098f71389063f54ee14422d9da22c57ad30d0"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.1.1/openframe-companion-0.1.1-darwin-amd64.tar.gz"
    sha256 "6bf47df9f5263830306fa730735d8217ff6fee95720372b2ff7492e8ea94ec9d"
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
