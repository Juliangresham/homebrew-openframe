class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.6.1"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.6.1/openframe-companion-0.6.1-darwin-arm64.tar.gz"
    sha256 "5ccde785ecfd09d5e4c5362b0d8dd6dbfd4daa2b7fc8255fa647a882d1f17435"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.6.1/openframe-companion-0.6.1-darwin-amd64.tar.gz"
    sha256 "a91bb17e2ba9185c607b78f9a4ef91d2b1733d017f4f732d867a8da3548e2b11"
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
