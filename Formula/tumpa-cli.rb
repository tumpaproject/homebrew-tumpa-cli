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
