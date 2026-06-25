class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://openframe.juliangresham.com"
  version "0.1.0"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.1.0/openframe-companion-0.1.0-darwin-arm64.tar.gz"
    sha256 "f7fd3154ce0c32aa167367c073f6157d08fade788018935174815d94c610b588"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.1.0/openframe-companion-0.1.0-darwin-amd64.tar.gz"
    sha256 "e87563e8257fd5d384f96fac2f30bcfb7a823f7212278488726c01785f806f0e"
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
