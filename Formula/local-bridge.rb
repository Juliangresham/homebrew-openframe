class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.4.2"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.4.2/openframe-companion-0.4.2-darwin-arm64.tar.gz"
    sha256 "8258899f85b5ad5c002af46af48f38eaa40f56e43150e085758d02abb326bbf1"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.4.2/openframe-companion-0.4.2-darwin-amd64.tar.gz"
    sha256 "4b9b7f55fe09eca1dd1464960f45c2760e5bbf729563cd6ef3ed3a4e639870e6"
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
