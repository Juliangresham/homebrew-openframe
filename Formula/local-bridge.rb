class LocalBridge < Formula
  desc "Open Frame local companion: trusted-HTTPS bridge to local Ollama"
  homepage "https://open-frame.app"
  version "0.2.4"

  on_arm do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.2.4/openframe-companion-0.2.4-darwin-arm64.tar.gz"
    sha256 "e7f07ee1593cd1a81eda013650b9a840dc077f885e1b03e562b153f6bc9f6f8e"
  end
  on_intel do
    url "https://github.com/Juliangresham/homebrew-openframe/releases/download/companion-v0.2.4/openframe-companion-0.2.4-darwin-amd64.tar.gz"
    sha256 "446bbb0feafb4fa614301cec972fb68f52a19c4e33c64e418a0ddb194f463dfe"
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
