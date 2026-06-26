class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://openframe.juliangresham.com"
  version "0.1.3"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.1.3/openframe-companion-0.1.3-darwin-arm64.tar.gz"
    sha256 "d582b67101e0c07f0af8de2ffabb20d71a1ca615e857e08bcdd3c03f9934af81"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.1.3/openframe-companion-0.1.3-darwin-amd64.tar.gz"
    sha256 "dcf54864e0ee3376506cfd9c36fb60544c53bbf28c4c1d2ce80a01a61e730cfa"
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
