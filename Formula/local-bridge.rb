class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://openframe.juliangresham.com"
  version "0.1.2"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.1.2/openframe-companion-0.1.2-darwin-arm64.tar.gz"
    sha256 "c4dc75fe127684b005e6b7b5417405f701fc4d3a3177f7223eb4bcac635c80ee"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.1.2/openframe-companion-0.1.2-darwin-amd64.tar.gz"
    sha256 "acf8d8701a23ab6f0a8c6748b265c225c44fedd0d65cfe3bcf1da9d82fffb8a8"
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
