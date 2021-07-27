{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-21.05";

    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
        let
          pkgs = import nixpkgs { system = system; };
        in
          {
            homeManagerConfig.programs.tmux = {
              enable = true;
              extraConfig = builtins.concatStringsSep "\n" [
                ''
                  bind-key -n F10 previous-window
                  bind-key -n F11 next-window
                  bind-key C-b last-window
                ''
              ];
              plugins = with pkgs.tmuxPlugins; [ gruvbox ];
              escapeTime = 0;
              keyMode = "vi";
              newSession = true;
              terminal = "xterm-256color";
            };
          }
    );
}
