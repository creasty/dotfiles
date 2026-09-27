{
  description = "creasty's dotfiles: macOS provisioned with nix-darwin and home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }:
    let
      system = "aarch64-darwin";

      mkDarwin =
        username: modules:
        nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit username;
            # The checkout the home directory links into, so that edits apply without a rebuild
            dotfiles = "/Users/${username}/dotfiles";
          };
          modules = [
            home-manager.darwinModules.home-manager
            ./nix/modules
          ]
          ++ modules;
        };
    in
    {
      # One configuration per user, which ./provision and ./verify pick with `#$(id -un)`
      darwinConfigurations = {
        creasty = mkDarwin "creasty" [ ];
        # The user of GitHub Actions' macOS runners, which have no Apple Account to install App Store apps with
        runner = mkDarwin "runner" [ { dotfiles.appStore = false; } ];
      };

      # Pinned tools for ./provision and ./verify
      packages.${system} = {
        inherit (nix-darwin.packages.${system}) darwin-rebuild;
        inherit (nixpkgs.legacyPackages.${system}) bats yq-go;
      };
    };
}
