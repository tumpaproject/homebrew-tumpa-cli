class TumpaCli < Formula
  desc "OpenPGP CLI and SSH agent backed by tumpa keystore"
  homepage "https://tumpa.rocks"
  license "GPL-3.0-or-later"

  on_macos do
    depends_on "pinentry-mac"

    on_arm do
      url "https://github.com/tumpaproject/tumpa-cli/releases/download/v0.5.1/tumpa-cli-aarch64-apple-darwin.tar.gz"
      sha256 "a2e3568040ab58b0d5d0568c9fcdc8ae470daa53a7c632bddbf56eed1ad6e59c"
    end
    on_intel do
      url "https://github.com/tumpaproject/tumpa-cli/releases/download/v0.5.1/tumpa-cli-x86_64-apple-darwin.tar.gz"
      sha256 "dd3994aad075c6a810824e2369440529b735d930669ac33cb2dd96f7f0d944bc"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/tumpaproject/tumpa-cli/releases/download/v0.5.1/tumpa-cli-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "5d3aaf49e04704954a1bc40752379ffa1cdd707b9dc4d9047fe03843bc098254"
    end
  end

  def install
    bin.install "tcli", "tclig", "tpass"
    generate_completions_from_executable(bin/"tcli", "completions")
    bash_completion.install "tpass.bash" => "tpass"
    zsh_completion.install "tpass.zsh" => "_tpass"
    fish_completion.install "tpass.fish"

    return unless OS.mac?

    # User LaunchAgent plist. Loaded only into the Aqua (GUI) session
    # so pinentry-mac can draw its dialog window. Homebrew's brew-services
    # mechanism cannot emit LimitLoadToSessionType=Aqua, so we deliberately
    # do NOT declare a `service do` block — users run `setup-tumpa-agent`
    # instead.
    (pkgshare/"in.kushaldas.tumpa.agent.plist").write <<~PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>in.kushaldas.tumpa.agent</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_bin}/tcli</string>
          <string>agent</string>
          <string>--ssh</string>
        </array>
        <key>LimitLoadToSessionType</key>
        <string>Aqua</string>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
        <key>EnvironmentVariables</key>
        <dict>
          <key>PATH</key>
          <string>#{HOMEBREW_PREFIX}/bin:/usr/local/bin:/usr/bin:/bin</string>
        </dict>
        <key>StandardOutPath</key>
        <string>#{var}/log/tumpa-agent.log</string>
        <key>StandardErrorPath</key>
        <string>#{var}/log/tumpa-agent.log</string>
        <key>ProcessType</key>
        <string>Interactive</string>
      </dict>
      </plist>
    PLIST

    (bin/"setup-tumpa-agent").write <<~SCRIPT
      #!/bin/bash
      # Install the Tumpa user LaunchAgent and clean up any stale
      # brew-services-managed instance. Idempotent — safe to re-run.
      set -euo pipefail

      LABEL="in.kushaldas.tumpa.agent"
      TARGET="$HOME/Library/LaunchAgents/${LABEL}.plist"
      SOURCE="#{opt_pkgshare}/in.kushaldas.tumpa.agent.plist"
      OLD_LABEL="homebrew.mxcl.tumpa-cli"
      OLD_PLIST="$HOME/Library/LaunchAgents/${OLD_LABEL}.plist"
      DOMAIN="gui/$(id -u)"
      LOG_PATH="#{var}/log/tumpa-agent.log"

      echo "==> Setting up $LABEL"

      if [ ! -f "$SOURCE" ]; then
        echo "ERROR: missing template plist at $SOURCE" >&2
        echo "       reinstall the formula:  brew reinstall tumpa-cli" >&2
        exit 1
      fi

      # 1. Stop the old brew-services-managed instance, if any.
      if command -v brew >/dev/null 2>&1; then
        if brew services list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "tumpa-cli"; then
          echo "--> brew services stop tumpa-cli"
          brew services stop tumpa-cli >/dev/null 2>&1 || true
        fi
      fi

      # 2. Bootout and remove the legacy plist.
      if launchctl print "${DOMAIN}/${OLD_LABEL}" >/dev/null 2>&1; then
        echo "--> launchctl bootout ${DOMAIN}/${OLD_LABEL}"
        launchctl bootout "${DOMAIN}/${OLD_LABEL}" >/dev/null 2>&1 || true
      fi
      if [ -f "$OLD_PLIST" ]; then
        echo "--> rm $OLD_PLIST"
        rm -f "$OLD_PLIST"
      fi

      # 3. If a previous run of this script left an instance loaded,
      #    bootout so we can re-bootstrap cleanly with the latest plist.
      if launchctl print "${DOMAIN}/${LABEL}" >/dev/null 2>&1; then
        echo "--> launchctl bootout ${DOMAIN}/${LABEL} (existing instance)"
        launchctl bootout "${DOMAIN}/${LABEL}" >/dev/null 2>&1 || true
      fi

      # 4. Install the plist.
      mkdir -p "$HOME/Library/LaunchAgents"
      cp "$SOURCE" "$TARGET"
      chmod 644 "$TARGET"
      echo "--> Installed $TARGET"

      # 5. Ensure the log destination exists and is writable.
      mkdir -p "$(dirname "$LOG_PATH")"

      # 6. Bootstrap into the Aqua GUI session.
      launchctl bootstrap "$DOMAIN" "$TARGET"
      launchctl enable "${DOMAIN}/${LABEL}" >/dev/null 2>&1 || true
      echo "--> Bootstrapped into $DOMAIN"

      # 7. Verify.
      sleep 1
      if launchctl print "${DOMAIN}/${LABEL}" >/dev/null 2>&1; then
        echo "==> Done. Agent socket: ~/.tumpa/agent.sock"
        echo "    Logs: $LOG_PATH"
      else
        echo "==> WARNING: agent did not register. Check $LOG_PATH" >&2
        exit 1
      fi
    SCRIPT
    chmod 0755, bin/"setup-tumpa-agent"
  end

  def caveats
    s = +""
    if OS.mac?
      s << <<~MACOS
        To install the Tumpa agent as a user LaunchAgent (recommended):
          setup-tumpa-agent

        DO NOT run `brew services start tumpa-cli`. Homebrew's service
        mechanism loads agents into the Background launchd session, which
        cannot reach WindowServer; pinentry-mac will silently fail and
        Tumpa Mail / smartcard PIN entry will appear "unavailable".

        setup-tumpa-agent is idempotent — safe to re-run after upgrades.
        It will:
          - stop `brew services` for tumpa-cli if it is running
          - remove ~/Library/LaunchAgents/homebrew.mxcl.tumpa-cli.plist if present
          - install ~/Library/LaunchAgents/in.kushaldas.tumpa.agent.plist
          - bootstrap and start it via `launchctl bootstrap gui/$(id -u)`

        To uninstall the agent later:
          launchctl bootout gui/$(id -u)/in.kushaldas.tumpa.agent
          rm ~/Library/LaunchAgents/in.kushaldas.tumpa.agent.plist

      MACOS
    end
    s << <<~EOS
      Add to your shell profile (~/.zshrc):
        export SSH_AUTH_SOCK="$HOME/.tumpa/tcli-ssh.sock"

      Import your OpenPGP key:
        tcli import /path/to/your/secret-key.asc

      Configure git:
        git config --global gpg.program tcli
        git config --global user.signingkey <FINGERPRINT>
        git config --global commit.gpgsign true
    EOS
    s
  end

  test do
    assert_match "tcli", shell_output("#{bin}/tcli --help 2>&1")
    assert_match "tpass", shell_output("#{bin}/tpass --help 2>&1")
  end
end
