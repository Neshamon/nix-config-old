{
  description = "Home Manager configuration of neshamon";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    wezterm-git = {
      url = "https://github.com/wez/wezterm.git";
      type = "git";
      submodules = true;
      flake = false;
    };

    stylix.url = "github:danth/stylix";
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOs/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, stylix, wezterm-git, nixos-hardware, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
    in {
      nixosConfigurations."neshamon" = nixpkgs.lib.nixosSystem {
        # inherit pkgs;

        specialArgs = { inherit inputs system wezterm-git; };
        #extraSpecialArgs = { inherit wezterm-git; };

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [
          stylix.nixosModules.stylix
          nixos-hardware.nixosModules.common-cpu-amd-pstate
          nixos-hardware.nixosModules.common-pc-ssd
          nixos-hardware.nixosModules.common-gpu-amd
          ./home.nix
          ./configuration.nix
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
      };
    };
}
