class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://openframe.juliangresham.com"
  version "0.1.0"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.1.0/openframe-companion-0.1.0-darwin-arm64.tar.gz"
    sha256 "e0c0cf65e565d8ffb9821c8fa8ace5e79f5f75e3dc39e7aed56b16532fddab5e"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.1.0/openframe-companion-0.1.0-darwin-amd64.tar.gz"
    sha256 "472df28cc8eb2e51c116719cca385f86a1bcbc9418e3daa94db3165d12615e51"
  end

  def install
    bin.install "openframe-companion"
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
