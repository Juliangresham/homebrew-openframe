class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.6.0"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.6.0/openframe-companion-0.6.0-darwin-arm64.tar.gz"
    sha256 "3866dcb4644d8bffd532e6a8ab75cd7e4a77de90af5b808e2e4cfc5508cf01fe"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.6.0/openframe-companion-0.6.0-darwin-amd64.tar.gz"
    sha256 "9cee993cb2077243260c931fbb224831892fa0c722fd45593273d4c1b5bd9f2d"
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
