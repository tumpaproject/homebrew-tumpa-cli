class TumpaCli < Formula
  desc "OpenPGP CLI and SSH agent backed by tumpa keystore"
  homepage "https://tumpa.rocks"
  version "0.1.1"
  license "GPL-3.0-or-later"

  on_macos do
    on_arm do
      url "https://github.com/tumpaproject/tumpa-cli/releases/download/v0.1.1/tumpa-cli-aarch64-apple-darwin.tar.gz"
      sha256 "a864df0756905bcaff10332032be67decd3195c298c45ce1e14823482aacfe81"
    end
    on_intel do
      url "https://github.com/tumpaproject/tumpa-cli/releases/download/v0.1.1/tumpa-cli-x86_64-apple-darwin.tar.gz"
      sha256 "2efc0ead3cf094576dab945cbb18e12cfeed2f249f007dee0d44609e1a6e4e18"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/tumpaproject/tumpa-cli/releases/download/v0.1.1/tumpa-cli-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "7ec5b7e801ff61ab1df97f8816645d03bd7ee95f442649efb013392111b9b4fb"
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
