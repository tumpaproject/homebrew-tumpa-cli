class TumpaCli < Formula
  desc "OpenPGP CLI and SSH agent backed by tumpa keystore"
  homepage "https://tumpa.rocks"
  license "GPL-3.0-or-later"

  on_macos do
    depends_on "pinentry-mac"

    on_arm do
      url "https://github.com/tumpaproject/tumpa-cli/releases/download/v0.2.0/tumpa-cli-aarch64-apple-darwin.tar.gz"
      sha256 "16fa3b59f18d87fee0843c311cb4e0e58e07a1a8019b4414f57c399ad983f4ad"
    end
    on_intel do
      url "https://github.com/tumpaproject/tumpa-cli/releases/download/v0.2.0/tumpa-cli-x86_64-apple-darwin.tar.gz"
      sha256 "83afcfe631b82644c99f018ae7e1e4bc4b8edccba50cf438902a959536298bef"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/tumpaproject/tumpa-cli/releases/download/v0.2.0/tumpa-cli-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "40981d474e714575b85679049f89602fd2c89dff9b3cb40d1527623ff41ee13d"
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
