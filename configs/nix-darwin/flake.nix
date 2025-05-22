# flake.nix
{
  description = "Darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }: {
    darwinConfigurations = {
      "stijn-macbook-pro" = nix-darwin.lib.darwinSystem {
        modules = [
          ./configuration.nix
          ./homebrew.nix
          {
            options = {
              isPersonal = nixpkgs.lib.mkOption {
                type = nixpkgs.lib.types.bool;
                default = false;
              };
            };
            config.isPersonal = true;
          }
        ];
      };
      "stijn-macbook-air" = nix-darwin.lib.darwinSystem {
        modules = [
          ./configuration.nix
          ./homebrew.nix
          {
            options = {
              isPersonal = nixpkgs.lib.mkOption {
                type = nixpkgs.lib.types.bool;
                default = false;
              };
            };
            config.isPersonal = false;
          }
        ];
      };
    };
  };
}