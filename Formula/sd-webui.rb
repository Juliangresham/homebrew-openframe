# frozen_string_literal: true

# packaging/homebrew/sd-webui.rb
#
# Stable Diffusion WebUI (AUTOMATIC1111), pinned to one commit, with its REST API on,
# run as a background service. Published to the juliangresham/openframe tap by
# .github/workflows/release-homebrew-formulae.yml, so users install it exactly like the
# companion:
#
#   brew install juliangresham/openframe/sd-webui
#   brew services start sd-webui
#
# A script formula, not a cask: nothing here is a binary we build, so nothing needs
# signing. The heavy work (torch, four helper repositories, the requirements) happens
# at INSTALL time, inside `post_install` (see the comment there for why not `install`),
# so the first service start takes seconds, not minutes. Everything the runtime writes
# at run time lives OUTSIDE the Cellar, in ~/OpenFrame, the one folder Open Frame keeps
# on a Mac: user data in ~/OpenFrame/dependencies/sd-webui (settings, outputs,
# extensions), checkpoints in ~/OpenFrame/dependencies/sd-models (mirroring
# ~/.ollama/models: installable and removable on their own), and its log in
# ~/OpenFrame/logs/sd-webui.log. The launcher moves the first two there from
# ~/.openframe, where they lived before revision 1. Uninstalling the formula leaves
# all of it alone.
class SdWebui < Formula
  desc "Stable Diffusion WebUI (AUTOMATIC1111) with its API on, for Open Frame"
  homepage "https://open-frame.app"
  # The v1.10.1 line. The COMMIT is the source of truth: it is the one verified end to
  # end on 2026-09-03 (Python 3.11, torch 2.3.1 on Apple Silicon).
  url "https://github.com/AUTOMATIC1111/stable-diffusion-webui.git",
      revision: "82a973c04367123ae98bd9abdf80d9eda9b910e2"
  version "1.10.1"
  license "AGPL-3.0-only"
  # Bumped whenever the launcher changes and the pinned version does not: without it,
  # `brew upgrade` sees nothing new and no Mac gets the new launcher. Revision 1 is the
  # ~/OpenFrame folder (2026-10). Not the `revision:` on the url line, the git commit.
  revision 1

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

  # Both formulas bind port 7860, and this one's launcher moves the other's data folders
  # (~/.openframe/image-runtime and image-models) into ~/OpenFrame when it starts, so
  # having the old service running while this one installs and starts moves that data out
  # from under the still-running process. Refuse the install outright rather than leave a
  # mess with no message; the caveats block below spells out the upgrade path.
  conflicts_with "image-gen-runtime", because: "both run Stable Diffusion WebUI on port 7860 and share its data directory"

  def install
    libexec.install Dir["*"]
    (bin/"sd-webui").write launcher(libexec/"venv")
    (bin/"sd-webui").chmod 0755
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
      # Stable Diffusion WebUI launcher for Open Frame (written by the Homebrew formula).
      # Runs AUTOMATIC1111 with its API on, bound to loopback, all data outside the Cellar.
      set -eu
      PY="#{venv}/bin/python"
      # BEGIN openframe-folder
      # Its folders and its log live in ~/OpenFrame, the one folder Open Frame keeps on this
      # Mac: data in dependencies/sd-webui, checkpoints in dependencies/sd-models, output in
      # logs/sd-webui.log. Any of ~/OpenFrame, dependencies/ and those two may be a link (to
      # another drive, or a share), and the launcher follows it. A folder it can't use stops it
      # with one line that says how to fix it, and nothing is written anywhere else; launchd
      # starts it again every 10 s, so it starts by itself once the drive is back or the fix is
      # done. Nothing else in this block may stop the launcher: under set -eu one failed step
      # would end it before its exec, with no line saying why. So every other step is an if, or
      # ends in || true.
      # scripts/run-sd-webui-launcher-test.mjs runs these exact lines, so they hold no
      # backslash and no hash followed by a brace, a dollar or an at sign: Ruby would rewrite
      # any of those, and the test would no longer run what ships.
      umask 077
      ROOT="$HOME/OpenFrame"
      DATA="$ROOT/dependencies/sd-webui"
      MODELS="$ROOT/dependencies/sd-models"
      LOGS="$ROOT/logs"
      OLD="$HOME/.openframe"
      ME="$(id -u 2>/dev/null)" || ME=""
      say() { echo "sd-webui: $*" || true; }
      show() { case "$1" in "$HOME"/*) echo "~/${1#"$HOME"/}" ;; *) echo "$1" ;; esac; }
      # A path as a person pastes it into Terminal: ~/ for the home folder, quoted when needed.
      cmd() { "$PY" -c 'import os,shlex,sys; p = sys.argv[1]; h = os.environ.get("HOME", ""); print("~/" + shlex.quote(p[len(h) + 1:]) if h and p.startswith(h + "/") else shlex.quote(p))' "$1" 2>/dev/null || show "$1"; }
      # One line saying why, then exit, so launchd tries again in 10 s.
      stop() { say "$*"; exit 1; }
      # What is at $1, links followed, then the folder it resolves to: absent; ok; missing (a
      # link whose target isn't there right now); alias (a Finder alias, which is a file, not a
      # link); file; owner (another user's); access (this user can't open it).
      look() {
        "$PY" -c 'import os,sys; p = sys.argv[1]; me = sys.argv[2] or str(os.getuid()); r = os.path.realpath(p); h = open(p, "rb").read(12) if os.path.isfile(p) and os.access(p, os.R_OK) else b""; print("absent" if not os.path.lexists(p) else "missing" if not os.path.exists(p) else ("alias" if h[:4] == b"book" and h[8:12] == b"mark" else "file") if not os.path.isdir(p) else "owner" if str(os.stat(p).st_uid) != me else "access" if not os.access(p, os.R_OK | os.W_OK | os.X_OK) else "ok", r)' "$1" "$ME" 2>/dev/null || echo "unknown $1"
      }
      # Sets REAL to the folder $1 resolves to, making it when nothing is there. One that can't
      # be used stops the launcher with the fix (never a fallback to another folder).
      use() {
        STATE="$(look "$1")"
        if [ "${STATE%% *}" = absent ]; then
          if ! ERR="$(mkdir -p "$1" 2>&1)"; then
            stop "can't create $(show "$1") ($(printf '%s' "$ERR" | tail -n 1 | sed 's/.*: //')), so Stable Diffusion WebUI can't start"
          fi
          STATE="$(look "$1")"
        fi
        REAL="${STATE#* }"
        SHOWN="$(show "$REAL")"
        if [ "$REAL" != "$1" ]; then SHOWN="$SHOWN (where $(show "$1") points)"; fi
        case "${STATE%% *}" in
          ok) ;;
          missing) stop "$(show "$1") points to $(show "$REAL"), which isn't available right now. Connect the drive (or mount the share) and Stable Diffusion WebUI starts by itself." ;;
          alias) stop "$SHOWN is a Finder alias, which Stable Diffusion WebUI can't follow. It should be the folder itself, or a link made in Terminal with ln -s." ;;
          file) stop "$SHOWN is a file, not a folder. It should be a folder: move that file somewhere else, and Stable Diffusion WebUI makes the folder by itself." ;;
          owner) stop "$SHOWN belongs to another user, so Stable Diffusion WebUI can't use it. To make it yours, run: sudo chown -R "'"$USER"'" $(cmd "$REAL")" ;;
          access) stop "$SHOWN can't be opened: its permissions don't let you in. To fix them, run: chmod u+rwx $(cmd "$REAL")" ;;
          *) stop "can't check $(show "$1"), so Stable Diffusion WebUI can't start" ;;
        esac
      }
      # Renames $1 to $2 only when nothing is at $2, so nothing is ever overwritten. os.rename
      # never copies: to another disk it fails ("it is on another disk"). A link moves as a
      # link, so a relative one, which would point somewhere else from $2, is refused. On a
      # failure REASON says why, in the system's words.
      rename_new() {
        REASON="it already exists"
        if [ -e "$2" ] || [ -L "$2" ]; then return 1; fi
        if REASON="$("$PY" -c 'import errno,os,sys; sys.excepthook=lambda t, e, tb: print("it is on another disk" if getattr(e, "errno", None) == errno.EXDEV else getattr(e, "strerror", None) or e, file=sys.stderr); s = sys.argv[1]; os.path.islink(s) and not os.path.isabs(os.readlink(s)) and sys.exit("it is a relative link, which would point somewhere else from there"); os.rename(s, sys.argv[2])' "$1" "$2" 2>&1)"; then return 0; fi
        REASON="$(printf '%s' "$REASON" | tail -n 1)"
        if [ -z "$REASON" ]; then REASON="the rename failed"; fi
        return 1
      }
      # A folder to move: a folder, a link to one, or a link whose target is not there now
      # (an external drive not mounted yet), which moves as a link like any other.
      present() { [ -d "$1" ] || { [ -L "$1" ] && [ ! -e "$1" ]; }; }
      # The size of a file or folder, in the decimal units Finder and the companion's uninstall use.
      size_of() {
        "$PY" -c 'import os,sys; p=sys.argv[1]; n=sum(os.lstat(os.path.join(r, f)).st_size for r, ds, fs in os.walk(p) for f in fs) if os.path.isdir(p) and not os.path.islink(p) else os.lstat(p).st_size; print("%.1f GB" % (n / 1e9) if n >= 1e9 else "%.1f MB" % (n / 1e6) if n >= 1e6 else "under 1 MB")' "$1" 2>/dev/null || echo "size unknown"
      }
      # The root first, before anything is written: its lines go to Homebrew's log.
      use "$ROOT"
      # The log. Everything below, and Stable Diffusion WebUI's own output, goes to
      # logs/sd-webui.log; one over 10 MB becomes sd-webui.old.log first, replacing the last.
      # One that can't be opened leaves the output in Homebrew's log, and the launcher goes on.
      if mkdir -p "$LOGS" 2>/dev/null; then
        if [ -f "$LOGS/sd-webui.log" ] && [ "$(wc -c < "$LOGS/sd-webui.log")" -gt 10000000 ] 2>/dev/null; then
          mv -f "$LOGS/sd-webui.log" "$LOGS/sd-webui.old.log" 2>/dev/null || true
        fi
        if { true >>"$LOGS/sd-webui.log"; } 2>/dev/null; then
          exec >>"$LOGS/sd-webui.log" 2>&1 || true
        else
          say "can't write $(show "$LOGS/sd-webui.log"), so this log stays in Homebrew's"
        fi
      else
        say "can't create $(show "$LOGS"), so this log stays in Homebrew's"
      fi
      use "$ROOT/dependencies"
      # The folder $1 resolves to, links followed, whether or not it is there right now.
      real() { "$PY" -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$1" 2>/dev/null || echo "$1"; }
      # Whether $1 and $2 are on the same disk.
      same_disk() { "$PY" -c 'import os,sys; sys.exit(0 if os.stat(sys.argv[1]).st_dev == os.stat(sys.argv[2]).st_dev else 1)' "$1" "$2" 2>/dev/null; }
      # Moves what the new folder $1 holds into the old real folder $2, then makes $1 a link to
      # $2. Each entry is renamed or, to another disk, copied with its mode under a hidden name
      # in $2 (.NAME.openframe-move), synced to the disk, compared by size and SHA-256, and only
      # then renamed to its own name and removed from $1. So a copy stopped part way (a SIGTERM
      # from brew services, a SIGKILL, a drive pulled) never leaves a short file under a real
      # name: a SIGTERM removes what it made, and the next start removes what anything else
      # left. A name $2 already has stays where it is. Exits 0 once $1 is the link, 3 when
      # something stays in $1, and says each step in one line.
      MERGE='
      import errno, hashlib, os, shutil, signal, stat, sys
      new, old = sys.argv[1], sys.argv[2]
      home = os.environ.get("HOME", "")
      def stopped(n, frame):
          sys.exit(128 + n)
      signal.signal(signal.SIGTERM, stopped)
      def show(p):
          return "~/" + p[len(home) + 1:] if home and p.startswith(home + "/") else p
      def say(s):
          print("sd-webui: " + s, flush=True)
      def size(p):
          if os.path.isdir(p) and not os.path.islink(p):
              return sum(os.lstat(os.path.join(r, f)).st_size for r, ds, fs in os.walk(p) for f in fs)
          return os.lstat(p).st_size
      def shown_size(n):
          return "%.1f GB" % (n / 1e9) if n >= 1e9 else "%.1f MB" % (n / 1e6) if n >= 1e6 else "under 1 MB"
      def digest(p):
          h = hashlib.sha256()
          with open(p, "rb") as f:
              for chunk in iter(lambda: f.read(1048576), b""):
                  h.update(chunk)
          return h.hexdigest()
      def unfinished(name):
          return os.path.join(old, "." + name + ".openframe-move")
      def discard(p):
          if os.path.isdir(p) and not os.path.islink(p):
              os.chmod(p, stat.S_IRWXU)
              for r, ds, fs in os.walk(p):
                  for d in ds:
                      if not os.path.islink(os.path.join(r, d)):
                          os.chmod(os.path.join(r, d), stat.S_IRWXU)
              shutil.rmtree(p)
          elif os.path.lexists(p):
              os.remove(p)
      def place(a, b):
          if os.path.lexists(b):
              raise OSError(errno.EEXIST, "it is there already")
          os.rename(a, b)
      def copy(a, b, modes):
          if os.path.islink(a):
              os.symlink(os.path.realpath(a), b)
          elif os.path.isdir(a):
              os.mkdir(b, 0o700)
              modes.append((b, os.stat(a).st_mode & 0o7777))
              for name in sorted(os.listdir(a)):
                  copy(os.path.join(a, name), os.path.join(b, name), modes)
          elif os.path.isfile(a):
              fd = os.open(b, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
              with open(a, "rb") as i, os.fdopen(fd, "wb") as o:
                  shutil.copyfileobj(i, o, 1048576)
                  o.flush()
                  os.fsync(o.fileno())
              os.chmod(b, os.stat(a).st_mode & 0o7777)
              if os.path.getsize(b) != os.path.getsize(a) or digest(b) != digest(a):
                  raise OSError(errno.EIO, "the copy did not match the original")
          else:
              raise OSError(errno.EINVAL, "it is not a file or a folder")
      def move(a, b):
          try:
              place(a, b)
              return
          except OSError as e:
              if e.errno != errno.EXDEV:
                  raise
          if shutil.disk_usage(old).free < size(a):
              raise OSError(errno.ENOSPC, "there is not enough free space there")
          t = unfinished(os.path.basename(b))
          modes = []
          try:
              copy(a, t, modes)
              for p, m in reversed(modes):
                  os.chmod(p, m)
              place(t, b)
          except BaseException:
              try:
                  discard(t)
              except OSError:
                  pass
              raise
          try:
              shutil.rmtree(a) if os.path.isdir(a) and not os.path.islink(a) else os.remove(a)
          except OSError as e:
              raise OSError(e.errno, "it was copied, but could not be removed here: " + (e.strerror or str(e)))
      for name in sorted(os.listdir(old)):
          if name.startswith(".") and name.endswith(".openframe-move") and len(name) > 16:
              try:
                  discard(os.path.join(old, name))
                  say("removed " + show(os.path.join(old, name)) + ", an unfinished copy from an earlier start")
              except OSError as e:
                  say("could not remove " + show(os.path.join(old, name)) + ", an unfinished copy from an earlier start (" + (e.strerror or str(e)) + ")")
      left = False
      for name in sorted(os.listdir(new)):
          if name == ".DS_Store":
              continue
          a, b = os.path.join(new, name), os.path.join(old, name)
          if os.path.lexists(b):
              say("left " + show(a) + " (" + shown_size(size(a)) + "): " + show(old) + " already has one")
              left = True
              continue
          try:
              move(a, b)
              say("moved " + show(a) + " to " + show(old))
          except OSError as e:
              say("could not move " + show(a) + " to " + show(old) + " (" + (e.strerror or str(e)) + "); it stays where it is")
              left = True
      if left:
          say(show(new) + " still holds files, so this start uses " + show(old) + ", and they stay where they are")
          sys.exit(3)
      try:
          if os.path.lexists(os.path.join(new, ".DS_Store")):
              os.remove(os.path.join(new, ".DS_Store"))
          os.rmdir(new)
          os.symlink(old, new)
      except OSError as e:
          say("could not make " + show(new) + " a link to " + show(old) + " (" + (e.strerror or str(e)) + "), so this start uses " + show(old))
          sys.exit(4)
      say(show(new) + " now points to " + show(old) + ", so the files there stay where they are and stay in use")
      '
      # Brings the old folder $1 into use at $2 (K6: a collection is never dropped, and never
      # copied to another disk). With nothing at $2: one on the same disk is renamed; one
      # behind a link, or one a rename can't move (another disk, a permission), stays where it
      # is, and $2 becomes a link to it. Something at $2 must be a folder this start can use
      # (a link to one is followed, K1), or the launcher stops with the fix. When $2 is a folder
      # (a model download made it) and the old one is behind a link or on another disk, what $2
      # holds moves into the old one, and $2 becomes the link. When $2 is a link the person
      # made, it is theirs and stays: an old one that holds nothing goes, and one that holds
      # files stops the launcher, naming both folders and the fix, since bringing them in would
      # mean copying to another disk or emptying a linked folder. USE is the folder this start
      # uses. Returns 1 when the old one is a folder on the same disk as the folder $2 resolves
      # to: the caller's step.
      bring_in() {
        USE="$2"
        if [ ! -e "$2" ] && [ ! -L "$2" ]; then
          if [ ! -L "$1" ] && rename_new "$1" "$2"; then
            say "moved $(show "$1") to $(show "$2")"
            return 0
          fi
          TO="$(real "$1")"
          if [ -L "$1" ]; then
            WHY="$(show "$2") now points to $(show "$TO"), as $(show "$1") did, so that folder stays where it is"
          else
            WHY="couldn't move $(show "$1") to $(show "$2") ($REASON), so $(show "$2") now points to it, and it stays where it is"
          fi
          if "$PY" -c 'import os,sys; os.symlink(sys.argv[1], sys.argv[2])' "$TO" "$2" 2>/dev/null; then
            say "$WHY"
            if [ -L "$1" ]; then rm -f "$1" 2>/dev/null || true; fi
          else
            say "couldn't move $(show "$1") to $(show "$2") or link it there, so this start uses $(show "$TO")"
            USE="$TO"
          fi
          return 0
        fi
        if [ "$(real "$2")" = "$(real "$1")" ]; then
          if [ -L "$1" ] && rm -f "$1" 2>/dev/null; then
            say "removed the link $(show "$1"): $(show "$2") points to the same folder"
          fi
          return 0
        fi
        use "$2"
        TO="$REAL"
        if [ ! -L "$1" ] && same_disk "$1" "$TO"; then return 1; fi
        use "$1"
        if [ -L "$2" ]; then
          if [ -n "$(ls -A "$1" 2>/dev/null | grep -v -x -F .DS_Store)" ]; then
            stop "$(show "$2") points to $(show "$TO"), and $SHOWN still holds files, which Stable Diffusion WebUI won't copy to another disk or take out of a linked folder. To use them, move what you want to keep into $(show "$TO"), then delete $(show "$1"), and Stable Diffusion WebUI starts by itself."
          fi
          if [ -L "$1" ]; then
            rm -f "$1" 2>/dev/null || true
          else
            rm -f "$1/.DS_Store" 2>/dev/null || true
            rmdir "$1" 2>/dev/null || true
          fi
          if [ ! -e "$1" ] && [ ! -L "$1" ]; then
            say "removed $(show "$1"), which held nothing: $(show "$2") points to $(show "$TO")"
          fi
          USE="$TO"
          return 0
        fi
        USE="$REAL"
        if "$PY" -c "$MERGE" "$2" "$REAL"; then
          if [ -L "$1" ]; then rm -f "$1" 2>/dev/null || true; fi
        else
          case "$?" in
            3|4) ;;
            *) say "couldn't bring $(show "$2") into $(show "$REAL"), so this start uses $(show "$REAL")" ;;
          esac
        fi
        return 0
      }
      # The move from ~/.openframe, once. image-runtime and image-models are the names this
      # formula used before 2026-09-06; a Mac that still has them moves them straight here.
      SRC="$OLD/sd-webui"
      if ! present "$SRC"; then SRC="$OLD/image-runtime"; fi
      if present "$SRC"; then
        if bring_in "$SRC" "$DATA"; then
          DATA="$USE"
        else
          say "left $(show "$SRC"): $(show "$DATA") already exists"
        fi
      fi
      SRC="$OLD/sd-models"
      if ! present "$SRC"; then SRC="$OLD/image-models"; fi
      if present "$SRC"; then
        if bring_in "$SRC" "$MODELS"; then
          MODELS="$USE"
        else
          # The new folder is there already (a model download made it, or it is a link the
          # person made), on the same disk as the old one: bring the old checkpoints in one by
          # one. A name in both places stays where it is, and the log says so with its size.
          for ENTRY in "$SRC"/* "$SRC"/.[!.]* "$SRC"/..?*; do
            if [ ! -e "$ENTRY" ] && [ ! -L "$ENTRY" ]; then continue; fi
            NAME="${ENTRY##*/}"
            if [ "$NAME" = ".DS_Store" ]; then continue; fi
            if rename_new "$ENTRY" "$MODELS/$NAME"; then
              say "moved $(show "$ENTRY") to $(show "$MODELS")"
            elif [ -e "$MODELS/$NAME" ] || [ -L "$MODELS/$NAME" ]; then
              say "left $(show "$ENTRY") ($(size_of "$ENTRY")): $(show "$MODELS") already has one"
            else
              say "couldn't move $(show "$ENTRY") to $(show "$MODELS") ($REASON); it stays where it is"
            fi
          done
          # Finder's .DS_Store is not a checkpoint: an old folder holding only that goes.
          if [ -z "$(ls -A "$SRC" 2>/dev/null | grep -v -x -F .DS_Store)" ]; then
            rm -f "$SRC/.DS_Store" 2>/dev/null || true
            rmdir "$SRC" 2>/dev/null || true
          fi
        fi
      fi
      # ~/.openframe goes once nothing is left in it. rmdir never removes a folder that holds
      # anything, such as a project saved there or files the companion has not moved yet.
      rmdir "$OLD" 2>/dev/null || true
      # The two folders, each made when it is not there, and each handed to Stable Diffusion
      # WebUI as the folder it resolves to. A link whose target isn't there right now waits
      # for it: creating a folder in its place would hide what it links to once it is back.
      use "$DATA"
      DATA="$REAL"
      use "$MODELS"
      MODELS="$REAL"
      # END openframe-folder
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
    run [opt_bin/"sd-webui"]
    keep_alive true
    log_path var/"log/sd-webui.log"
    error_log_path var/"log/sd-webui.log"
  end

  def caveats
    <<~EOS
      Stable Diffusion WebUI keeps its settings and the images it makes in
      ~/OpenFrame/dependencies/sd-webui, its checkpoints in
      ~/OpenFrame/dependencies/sd-models, and its log in ~/OpenFrame/logs/sd-webui.log.
      Its first start after this update moves the first two there from ~/.openframe by
      itself. Uninstalling it leaves all three where they are.

      The first update to this version can take 10 to 20 minutes while it rebuilds;
      after that, a minute or so.

      Upgrading from the old image-gen-runtime formula? Stop and remove it FIRST,
      before starting this one:

        brew services stop image-gen-runtime && brew uninstall image-gen-runtime

      Both bind port 7860 and share the same data directory, so running them at the
      same time corrupts state. Once that's done, this formula's first start moves
      ~/.openframe/image-runtime and ~/.openframe/image-models into
      ~/OpenFrame/dependencies, one time, so nothing is re-downloaded.
    EOS
  end

  test do
    assert_path_exists libexec/"venv/bin/python"
    assert_match "--api", (bin/"sd-webui").read
    assert_predicate bin/"sd-webui", :executable?
  end
end
