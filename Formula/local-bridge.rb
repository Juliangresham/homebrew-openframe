class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.11.0"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.11.0/openframe-companion-0.11.0-darwin-arm64.tar.gz"
    sha256 "e8da4772df09fd879a7683bcc493a46455ade266010fcf8f2942d8e85393538b"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.11.0/openframe-companion-0.11.0-darwin-amd64.tar.gz"
    sha256 "1f6e98dba35937c9b4d6af389219f356bbbf39fdc64f48ffe062062ad9f6ad8e"
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
