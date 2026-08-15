class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.4.4"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.4.4/openframe-companion-0.4.4-darwin-arm64.tar.gz"
    sha256 "87039e15d0a210420842dc1bb5dc9e07b1587a169311b4d74594cc016147c721"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.4.4/openframe-companion-0.4.4-darwin-amd64.tar.gz"
    sha256 "1150687f9c0ebc7a4fa97fc458d45c569182da589a94c9693848deefd8e2e0a9"
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
