class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.3.7"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.3.7/openframe-companion-0.3.7-darwin-arm64.tar.gz"
    sha256 "26fc40cc653732b65ac791a9e0d5217d934f0ed41f63a2d9722e9d776fd236a1"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.3.7/openframe-companion-0.3.7-darwin-amd64.tar.gz"
    sha256 "a56a78d4d6d5b6f752c7e202442eeb96efea32f4c20790281a8603f9d4847f9d"
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
