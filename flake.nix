{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager = {
      #url = "github:nix-community/home-manager/release-24.05";
      url = "github:nix-community/home-manager"; #unstable / master(?)
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
      #inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    distro-grub-themes.url = "github:AdisonCavani/distro-grub-themes";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    stylix.url = "github:danth/stylix";

    alejandra = {
      url = "github:kamadorueda/alejandra/3.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fw-fanctrl = {
      url = "github:TamtamHero/fw-fanctrl/packaging/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    #nixpkgs-staging.url = "github:nixos/nixpkgs/staging";
    #master.url = "github:nixos/nixpkgs/master";

    #github:JaKooLit/NixOS-Hyprland

    #nixos-vfio.url = "github:j-brn/nixos-vfio";
    #inputs.flake-compat = {
    #  url = "github:edolstra/flake-compat";
    #  flake = false;
    #};
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    stylix,
    alejandra,
    nixos-hardware,
    fw-fanctrl,
    ...
  }: let
    system = "x86_64-linux";
    host = "nixos";
    laptop-host = "nixtop";
    nixserver = "nixserver";
    username = "ajhyperbit";
    home = "/home/ajhyperbit";
    stateVersion-host = "23.11";
    stateVersion-laptop-host = "23.11";
    #This is due to the fact home manager got installed on 24.05 and NOT 23.11.
    #I am prioritizing keeping stateVersion accurate across files and preventing breakage,
    #but upon a reinstall or a requirement of bumping stateVersion I will try to change this
    #so stateVersion-host and stateVersion-hm can be the same so stateVersion-hm can be removed
    stateVersion-hm = "24.05";

    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };
  in {
    nixosConfigurations = {
      #Main Desktop
      "${host}" = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = {
          inherit system;
          inherit inputs;
          inherit username;
          inherit host;
          inherit home;
          inherit self;
          inherit stateVersion-host;
          inherit stateVersion-hm;
        };
        modules = [
          ./hosts/${host}/config.nix
          ./hosts/${host}/hardware.nix
          ./hosts/${host}/drives.nix
          ./hosts/common/common.nix
          ./hosts/common/users.nix
          ./modules/nvidia-drivers.nix
          ./modules/vm-guest-services.nix
          #nixos-hardware.nixosModules.framework-11th-gen-intel
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ajhyperbit = {
              imports = [
                ./hosts/common/home.nix
                ./hosts/${host}/home.nix
              ];
            };
            home-manager.extraSpecialArgs = {inherit inputs self username stateVersion-hm;};
            home-manager.backupFileExtension = "backup";
          }

          stylix.nixosModules.stylix

          {
            environment.systemPackages = [alejandra.defaultPackage.${system}];
          }

          (
            {pkgs, ...}: {
              environment.systemPackages = [
              ];
            }
          )

          #fufexan-dotfiles.packages.${system}.bibata-hyprcursor
          #fufexan-dotfiles.nixosModules.theme

          #nixos-vfio.nixosModules.vfio
          #wayland.windowManager.hyprland {
          #  enable = true;
          #  package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
          #}
        ];
      };
      #Framework13
      "${laptop-host}" = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = {
          inherit system;
          inherit inputs;
          inherit username;
          inherit laptop-host;
          inherit self;
          inherit stateVersion-laptop-host;
          inherit stateVersion-hm;
        };
        modules = [
          ./hosts/${laptop-host}/config.nix
          ./hosts/${laptop-host}/hardware.nix
          ./hosts/common/common.nix
          ./hosts/common/users.nix
          ./modules/intel-drivers.nix
          nixos-hardware.nixosModules.framework-11th-gen-intel
          home-manager.nixosModules.home-manager
          fw-fanctrl.nixosModules.default
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ajhyperbit = {
              imports = [
                ./hosts/common/home.nix
                ./hosts/${laptop-host}/home.nix
              ];
            };
            home-manager.extraSpecialArgs = {inherit inputs self username stateVersion-hm;};
            home-manager.backupFileExtension = "backup";
          }
          stylix.nixosModules.stylix

          {
            environment.systemPackages = [alejandra.defaultPackage.${system}];
          }

          (
            {pkgs, ...}: {
              environment.systemPackages = [
              ];
            }
          )
        ];
      };
      #Yet to be built server (someday)
      #"${nixserver}" = nixpkgs.lib.nixosSystem rec {
      #  system = "x86_64-linux";
      #  specialArgs = {
      #    inherit system;
      #    inherit inputs;
      #    inherit username;
      #    inherit nixserver;
      #    inherit self;
      #  };
      #  modules = [
      #    ./hosts/${nixserver}/config.nix
      #    ./hosts/${nixserver}/hardware.nix
      #    ./hosts/server/server.nix
      #    ./hosts/common/users.nix
      #    home-manager.nixosModules.home-manager
      #    {
      #      home-manager.useGlobalPkgs = true;
      #      home-manager.useUserPackages = true;
      #      home-manager.users.ajhyperbit = {imports = [./config/home.nix];};
      #      home-manager.extraSpecialArgs = {inherit inputs self username;};
      #      home-manager.backupFileExtension = "backup";
      #    }
      #    stylix.nixosModules.stylix
      #    ({pkgs, ...}: {
      #      environment.systemPackages = [
      #      ];
      #    })
      #  ];
      #};
    };
  };
}
