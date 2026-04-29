class TumpaCli < Formula
  desc "OpenPGP CLI and SSH agent backed by tumpa keystore"
  homepage "https://tumpa.rocks"
  license "GPL-3.0-or-later"

  on_macos do
    depends_on "pinentry-mac"

    on_arm do
      url "https://github.com/tumpaproject/tumpa-cli/releases/download/v0.5.0/tumpa-cli-aarch64-apple-darwin.tar.gz"
      sha256 "83cf3f1ef06e2b375d67f1357a0caffa3d219405376ba9f3a834f8ca02599476"
    end
    on_intel do
      url "https://github.com/tumpaproject/tumpa-cli/releases/download/v0.5.0/tumpa-cli-x86_64-apple-darwin.tar.gz"
      sha256 "632501cd694995d324bf8fb6bf320baea6a0e92a524c8f21ce1f02bce15715dc"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/tumpaproject/tumpa-cli/releases/download/v0.5.0/tumpa-cli-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "aa8958cf9e349f0d69bf4a35bec40d1c827689e2095aec64141fa4dfca588635"
    end
  end

  def install
    bin.install "tcli", "tclig", "tpass"
    generate_completions_from_executable(bin/"tcli", "completions")
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
        tcli import /path/to/your/secret-key.asc

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
