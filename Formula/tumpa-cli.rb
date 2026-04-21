class TumpaCli < Formula
  desc "OpenPGP CLI and SSH agent backed by tumpa keystore"
  homepage "https://tumpa.rocks"
  license "GPL-3.0-or-later"

  on_macos do
    depends_on "pinentry-mac"

    on_arm do
      url "https://github.com/tumpaproject/tumpa-cli/releases/download/v0.3.2/tumpa-cli-aarch64-apple-darwin.tar.gz"
      sha256 "9be07ad59ced00fdb1b5a368508747a53c6bd37c35a8cd72fb97da72fff74a47"
    end
    on_intel do
      url "https://github.com/tumpaproject/tumpa-cli/releases/download/v0.3.2/tumpa-cli-x86_64-apple-darwin.tar.gz"
      sha256 "5074bc005b4baa5e7f6d6db3daeb4df240d95855dd2b4173043bc1661425b624"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/tumpaproject/tumpa-cli/releases/download/v0.3.2/tumpa-cli-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "8251c684de579192cc9a8178c5f537d7f693d2ad21c557249473ff8258a2fe6d"
    end
  end

  def install
    bin.install "tcli", "tclig", "tpass"
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
