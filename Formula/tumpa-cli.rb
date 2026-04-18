class TumpaCli < Formula
  desc "OpenPGP CLI and SSH agent backed by tumpa keystore"
  homepage "https://tumpa.rocks"
  license "GPL-3.0-or-later"

  on_macos do
    depends_on "pinentry-mac"

    on_arm do
      url "https://github.com/tumpaproject/tumpa-cli/releases/download/v0.3.1/tumpa-cli-aarch64-apple-darwin.tar.gz"
      sha256 "719c440327515010a70e68ba1dbc3fdd04e01eb79424483c638f64e68d880bbf"
    end
    on_intel do
      url "https://github.com/tumpaproject/tumpa-cli/releases/download/v0.3.1/tumpa-cli-x86_64-apple-darwin.tar.gz"
      sha256 "8f6bb92db6cb533b87dab1068bcdfb1083c6b71f5823862156e1cb928de173c3"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/tumpaproject/tumpa-cli/releases/download/v0.3.1/tumpa-cli-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "ffdb6291b259644c9df96c0b3671590a6cc9f276c1127148eb3454a1033926cb"
    end
  end

  def install
    bin.install "tcli", "tpass"
    generate_completions_from_executable(bin/"tcli", "--completions")
    bash_completion.install "tpass.bash" => "tpass"
    zsh_completion.install "tpass.zsh" => "_tpass"
    fish_completion.install "tpass.fish"
  end

  service do
    run [opt_bin/"tcli", "agent", "--ssh"]
    keep_alive true
    log_path var/"log/tumpa-agent.log"
    error_log_path var/"log/tumpa-agent.log"
  end

  def caveats
    <<~EOS
      To start the agent on login:
        brew services start tumpa-cli

      Add to your shell profile (~/.zshrc):
        export SSH_AUTH_SOCK="$HOME/.tumpa/tcli-ssh.sock"

      Import your OpenPGP key:
        tcli --import /path/to/your/secret-key.asc

      Configure git:
        git config --global gpg.program tcli
        git config --global user.signingkey <FINGERPRINT>
        git config --global commit.gpgsign true
    EOS
  end

  test do
    assert_match "tcli", shell_output("#{bin}/tcli --help 2>&1")
    assert_match "tpass", shell_output("#{bin}/tpass --help 2>&1")
  end
end
