class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://openframe.juliangresham.com"
  version "0.2.1"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.2.1/openframe-companion-0.2.1-darwin-arm64.tar.gz"
    sha256 "a3c97272fda103a10264be026020583c4af284b6f634845bf95be8c04d7bc4d1"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.2.1/openframe-companion-0.2.1-darwin-amd64.tar.gz"
    sha256 "c7e015878e0703ec3ab9f6b6a1aa2030cb2c154eb3b9a7467a3fd1afb2280bc9"
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
