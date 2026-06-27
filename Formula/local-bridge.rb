class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://openframe.juliangresham.com"
  version "0.2.0"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.2.0/openframe-companion-0.2.0-darwin-arm64.tar.gz"
    sha256 "99eb306421e5c17a6cf526f449a7b48a5fd6c24e47e384e6af380755df4300a5"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.2.0/openframe-companion-0.2.0-darwin-amd64.tar.gz"
    sha256 "ec6e456aa704e71e2ab8f64e0ffc9c57d60a0500a9e55e1de8c3b5ce66490651"
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
