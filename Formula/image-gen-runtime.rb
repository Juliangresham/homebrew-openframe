# frozen_string_literal: true

# packaging/homebrew/image-gen-runtime.rb
#
# The Open Frame image generation runtime: AUTOMATIC1111's Stable Diffusion web UI,
# pinned to one commit, with its REST API on, run as a background service. Published
# to the juliangresham/openframe tap by .github/workflows/release-image-gen-runtime.yml,
# so users install it exactly like the companion:
#
#   brew install juliangresham/openframe/image-gen-runtime
#   brew services start image-gen-runtime
#
# A script formula, not a cask: nothing here is a binary we build, so nothing needs
# signing. The heavy work (torch, four helper repositories, the requirements) happens
# at INSTALL time, inside `post_install` (see the comment there for why not `install`),
# so the first service start takes seconds, not minutes. Everything the runtime writes
# at run time lives OUTSIDE the Cellar: user
# data in ~/.openframe/image-runtime (settings, outputs, extensions), checkpoints in
# ~/.openframe/image-models (mirroring ~/.ollama/models: installable and removable on
# their own). Uninstalling the formula leaves both folders alone.
class ImageGenRuntime < Formula
  desc "AUTOMATIC1111 Stable Diffusion API runtime for Open Frame"
  homepage "https://open-frame.app"
  # The v1.10.1 line. The COMMIT is the source of truth: it is the one verified end to
  # end on 2026-09-03 (Python 3.11, torch 2.3.1 on Apple Silicon).
  url "https://github.com/AUTOMATIC1111/stable-diffusion-webui.git",
      revision: "82a973c04367123ae98bd9abdf80d9eda9b910e2"
  version "1.10.1"
  license "AGPL-3.0-only"

  # NO `depends_on "git"`, deliberately, and please do not add it back.
  #
  # Git IS needed, both to fetch the url above and by `launch.py`, which clones this runtime's
  # pinned repositories during post_install. It is simply already there: Homebrew cannot run
  # without the Xcode command line tools, which ship /usr/bin/git, and Homebrew's own download
  # strategy calls Utils::Git.ensure_installed! and pulls the git formula itself in the rare
  # case that git really is unusable. Declaring it bought nothing.
  #
  # What it COST was real. The dependency poured Homebrew's git into /opt/homebrew/bin, ahead
  # of Apple's on PATH. macOS binds a keychain credential to the specific binaries allowed to
  # read it, so replacing the git binary orphaned a github.com credential stored years earlier:
  # the helper returned -128 (errSecUserCanceled) and every `git push` from a non-interactive
  # shell failed with "could not read Username". Installing an image generator should not
  # rearrange the user's git, and a formula that re-pours that binary on every reinstall
  # re-breaks it each time.
  depends_on "python@3.11"

  def install
    libexec.install Dir["*"]
    (bin/"image-gen-runtime").write launcher(libexec/"venv")
    (bin/"image-gen-runtime").chmod 0755
  end

  # Building the venv here, and not in `install`, is load-bearing, not a style choice.
  # `formula_installer.rb` calls `fix_dynamic_linkage(keg)` right after `install` returns,
  # and only calls `post_install` afterwards: that relocation step rewrites the dylib ID of
  # every Mach-O it finds in the keg, and rewriting the ID of a dylib that shipped
  # pre-signed inside a Python wheel (numpy, torch, torchvision all bundle several)
  # invalidates its code signature. On Apple Silicon the kernel SIGKILLs any process that
  # loads a library whose signature no longer matches its contents, silently and with no
  # log output. Measured on this machine 2026-09-03: with the venv built in `install`,
  # `import numpy` inside the installed venv died with signal 9 every time, while the
  # identical wheel in a venv built outside Homebrew's relocation path imported cleanly.
  # Building the venv in `post_install` sidesteps the rewrite entirely, since relocation
  # has already finished by the time this runs. Do not move this back into `install`.
  def post_install
    python = formula_opt_bin("python@3.11")/"python3.11"
    venv = libexec/"venv"
    system python, "-m", "venv", venv
    # The two fresh-install breakages every clone hits today, worked around here so no
    # user ever meets them: the pinned CLIP package imports pkg_resources, which
    # setuptools 80 removed (so pin setuptools and install CLIP without build isolation);
    # and Stability-AI/stablediffusion was deleted from GitHub in December 2025 (the
    # maintainers' fork carries the identical pinned commit).
    system venv/"bin/pip", "install", "--upgrade", "pip", "setuptools<80"
    # Install the pinned torch/torchvision explicitly, and BEFORE the CLIP install below.
    # CLIP's setup.py lists torch as an unpinned dependency, so if CLIP installs first, pip
    # resolves whatever torch is newest at that moment: measured on this machine, CLIP-first
    # produced torch 2.12.1 / torchvision 0.27.1 instead of the pinned 2.3.1 / 0.18.1 that
    # this runtime version is actually tested against. Worse, by the time launch.py runs its
    # own TORCH_COMMAND step, `is_installed("torch")` is already true, so the pin is silently
    # skipped rather than corrected. Installing the exact pin here first means CLIP's
    # dependency is already satisfied and pip leaves it alone. Do not reorder these two
    # installs, or the version pin silently stops applying again.
    system venv/"bin/pip", "install", *torch_pip_args
    system venv/"bin/pip", "install", "--no-build-isolation",
           "https://github.com/openai/CLIP/archive/d50d76daa670286dd6cacf3bcd80b5e4823fc8e1.zip"
    # Prepare the whole environment now, what the first `./webui.sh` would otherwise do
    # on the user's first start: the helper repositories, the requirements. TORCH_COMMAND
    # is still set as a belt-and-braces fallback (launch.py runs it if it ever finds torch
    # missing); the explicit pinned install above is what actually fixes the version in the
    # normal case, since by this point is_installed("torch") already short-circuits it.
    ENV["STABLE_DIFFUSION_REPO"] = "https://github.com/w-e-w/stablediffusion.git"
    ENV["TORCH_COMMAND"] = torch_command
    ENV["COMMANDLINE_ARGS"] = ""
    cd libexec do
      system venv/"bin/python", "launch.py", "--skip-torch-cuda-test", "--exit"
    end
  end

  # Single source of truth for the pinned torch/torchvision versions: the explicit
  # `pip install` in post_install and the TORCH_COMMAND fallback both build from this, so
  # the versions are never written twice and cannot drift apart. The versions themselves
  # are the torch build the web UI's own macOS launcher picks (webui-macos-env.sh); Linux
  # uses the CUDA-targeted wheels (cu121), the standard build path on Linux.
  def torch_pip_args
    if OS.mac?
      if Hardware::CPU.arm?
        %w[torch==2.3.1 torchvision==0.18.1]
      else
        %w[torch==2.1.2 torchvision==0.16.2]
      end
    else
      ["torch==2.1.2", "torchvision==0.16.2", "--extra-index-url", "https://download.pytorch.org/whl/cu121"]
    end
  end

  def torch_command
    "pip install #{torch_pip_args.join(" ")}"
  end

  def launcher(venv)
    mps_flags = OS.mac? ? "--upcast-sampling --no-half-vae --use-cpu interrogate" : ""
    <<~SH
      #!/bin/bash
      # Open Frame image generation runtime launcher (written by the Homebrew formula).
      # Runs AUTOMATIC1111 with its API on, bound to loopback, all data outside the Cellar.
      set -eu
      DATA="$HOME/.openframe/image-runtime"
      MODELS="$HOME/.openframe/image-models"
      mkdir -p "$DATA" "$MODELS"
      # The runtime opens its own page in the default browser on every start unless its
      # settings say otherwise. A background service must never do that.
      if [ ! -f "$DATA/config.json" ]; then
        printf '{\\n  "auto_launch_browser": "Disable"\\n}\\n' > "$DATA/config.json"
      fi
      # One optional line of extra flags, for developers (a --cors-allow-origins with a
      # local dev origin, say). Not a user-facing setting.
      EXTRA=""
      if [ -f "$DATA/args" ]; then EXTRA="$(cat "$DATA/args")"; fi
      export PYTORCH_ENABLE_MPS_FALLBACK=1
      cd "#{libexec}"
      # shellcheck disable=SC2086
      exec "#{venv}/bin/python" launch.py --skip-prepare-environment --api --skip-torch-cuda-test \\
        #{mps_flags} --no-download-sd-model --port 7860 \\
        --data-dir "$DATA" --ckpt-dir "$MODELS" \\
        --cors-allow-origins=https://open-frame.app $EXTRA
    SH
  end

  service do
    run [opt_bin/"image-gen-runtime"]
    keep_alive true
    log_path var/"log/image-gen-runtime.log"
    error_log_path var/"log/image-gen-runtime.log"
  end

  test do
    assert_path_exists libexec/"venv/bin/python"
    assert_match "--api", (bin/"image-gen-runtime").read
    assert_predicate bin/"image-gen-runtime", :executable?
  end
end
