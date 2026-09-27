# VS Code, with the dotfiles' settings and these extensions (code --list-extensions)
{ username, ... }:
let
  extensions = [
    "alygin.vscode-tlaplus"
    "anthropic.claude-code"
    "apollographql.vscode-apollo"
    "christian-kohler.npm-intellisense"
    "christian-kohler.path-intellisense"
    "creasty.vscode-altr"
    "creasty.vscode-pattern-switch"
    "dbaeumer.vscode-eslint"
    "eamodio.gitlens"
    "eg2.vscode-npm-script"
    "esbenp.prettier-vscode"
    "formulahendry.auto-close-tag"
    "formulahendry.auto-rename-tag"
    "github.vscode-github-actions"
    "golang.go"
    "jock.svg"
    "ms-python.debugpy"
    "ms-python.python"
    "ms-python.vscode-pylance"
    "ms-python.vscode-python-envs"
    "ms-vsliveshare.vsliveshare"
    "pflannery.vscode-versionlens"
    "sleistner.vscode-fileutils"
    "steoates.autoimport"
    "streetsidesoftware.code-spell-checker"
    "styled-components.vscode-styled-components"
    "swindh.enumerator"
    "tamasfe.even-better-toml"
    "tyriar.sort-lines"
    "vincaslt.highlight-matching-tag"
    "wayou.vscode-todo-highlight"
    "wmaurer.change-case"
    "wwm.better-align"
    "yahyabatulu.vscode-markdown-alert"
  ];

  userDir = "Library/Application Support/Code/User";
in
{
  homebrew.casks = [ "visual-studio-code" ];

  home-manager.users.${username} =
    { lib, ... }:
    {
      dotfiles.link = {
        "${userDir}/settings.json" = "vscode/settings.json";
        "${userDir}/keybindings.json" = "vscode/keybindings.json";
      };

      # The marketplace occasionally answers 5xx, hence the retries
      home.activation.installVscodeExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        code=/opt/homebrew/bin/code
        installed="$("$code" --list-extensions | tr '[:upper:]' '[:lower:]')"
        for extension in ${lib.escapeShellArgs extensions}; do
          lowercase="$(printf '%s' "$extension" | tr '[:upper:]' '[:lower:]')"
          grep -qxF -- "$lowercase" <<< "$installed" && continue
          for attempt in 1 2 3 4; do
            run "$code" --install-extension "$extension" && break
            [ "$attempt" -lt 4 ] || exit 1
            sleep 10
          done
        done
      '';
    };

  dotfiles.manifest.vscode.extensions = extensions;
}
