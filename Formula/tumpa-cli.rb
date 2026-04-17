class TumpaCli < Formula
  desc "OpenPGP CLI and SSH agent backed by tumpa keystore"
  homepage "https://tumpa.rocks"
  license "GPL-3.0-or-later"

  on_macos do
    depends_on "pinentry-mac"

    on_arm do
      url "https://github.com/tumpaproject/tumpa-cli/releases/download/v0.3.0/tumpa-cli-aarch64-apple-darwin.tar.gz"
      sha256 "c29ea09cd323cd3a129f7851ea5e8a533397ed887f005a459b8b3f0b81e411df"
    end
    on_intel do
      url "https://github.com/tumpaproject/tumpa-cli/releases/download/v0.3.0/tumpa-cli-x86_64-apple-darwin.tar.gz"
      sha256 "0179f120cbd7dfb87872cbf65b91943920c99fc82c43321451f7028ad27de0f8"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/tumpaproject/tumpa-cli/releases/download/v0.3.0/tumpa-cli-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "0d7ac30b7eb2aac67ad300f9e6a72f487052fe420d882747f37145a6557d64ba"
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
