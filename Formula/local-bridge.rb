class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.10.0"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.10.0/openframe-companion-0.10.0-darwin-arm64.tar.gz"
    sha256 "e78843d2aa67d20c6da64d9fbd9a31120b3151c9f280316b3fd096ad6d6a7490"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.10.0/openframe-companion-0.10.0-darwin-amd64.tar.gz"
    sha256 "663f9cf5aef53590ba9d07bd6a833dabbe4101af5d9f7f6eb274a0957b75e4fd"
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
