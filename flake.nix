{
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11"; # Stable channel for everything else
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable"; # Unstable channel
    nixos-wsl.url = "git+ssh://git@github.com/nix-community/NixOS-WSL.git"; # NixOS WSL
    nixpkgs-oldvscode.url = "github:NixOS/nixpkgs/333d19c8b58402b94834ec7e0b58d83c0a0ba658"; # vscode 1.98.2
    flatpaks.url = "git+ssh://git@github.com/in-a-dil-emma/declarative-flatpak.git";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

    alejandra = {
      # Nix formatter -> https://drakerossman.com/blog/overview-of-nix-formatters-ecosystem
      url = "git+ssh://git@github.com/kamadorueda/alejandra.git?ref=refs/tags/4.0.0";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    astal = {
      url = "git+ssh://git@github.com/aylur/astal.git";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    ags = {
      url = "git+ssh://git@github.com/aylur/ags.git";
      inputs.nixpkgs.follows = "nixpkgs-stable";
      inputs.astal.follows = "astal";
    };

    adwaita_hypercursor = {
      url = "git+ssh://git@github.com/dp0sk/Adwaita-HyprCursor.git";
      flake = false;
    };

    claude = {
      url = "git+ssh://git@github.com/k3d3/claude-desktop-linux-flake.git";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    disko = {
      url = "git+ssh://git@github.com/nix-community/disko.git";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    sops-nix = {
      url = "git+ssh://git@github.com/Mic92/sops-nix.git";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    vscode-server = {
      url = "git+ssh://git@github.com/nix-community/nixos-vscode-server.git";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    firefox-gnome-theme = {
      url = "git+ssh://git@github.com/rafaelmardojai/firefox-gnome-theme.git";
      flake = false;
    };

    tim-nvim = {
      url = "git+ssh://git@github.com/timlisemer/nvim.git";
      flake = false;
    };

    restic-backup-service = {
      url = "git+ssh://git@github.com/timlisemer/restic-backup-service.git";
      # url = "path:/home/tim/Coding/Other/restic-backup-service"; # for local development
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
  };

  # Optional: Binary cache for the nixos-raspberrypi flake
  nixConfig = {
    extra-substituters = ["https://nixos-raspberrypi.cachix.org"];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  outputs = inputs @ {
    self,
    nixpkgs-stable,
    nixpkgs-unstable,
    nixpkgs-oldvscode,
    flatpaks,
    disko,
    alejandra,
    sops-nix,
    vscode-server,
    home-manager,
    firefox-gnome-theme,
    nixos-wsl,
    nixos-raspberrypi,
    adwaita_hypercursor,
  
      claude,
    rust-overlay,
    ...
  }: let hostIps = {
      "konrad-laptop" = "10.0.0.25";
      "konrad-pc" = "10.0.0.3";
      "konrad-server" = "142.132.234.128";
      "konrad-pi4" = "10.0.0.76";
      "homeassistant-yellow" = "10.0.0.2";
      "traefik.local.yakweide.de" = "10.0.0.2";
      "pihole.local.yakweide.de" = "10.0.0.2";
    };
    users = {
      konrad = {
        fullName = "Konrad Hirschkorn";
        gitUsername = "Konrad-hirschkorn";
        gitEmail = "konrad.hirschkorn@gmail.com";
        hashedPassword = "$6$Kz1nBiLtUiNHtmei$cMGqIjNE9zoWrY4wy5LQT7gI2aGXczlsQajTfkaFgkDmmipyEuAeIHUS1MsuanmJnjEEYXdfOnjaoSLRHHoSO1";
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID9CPAbuRYetl4yuI21KUL0DkDWm/a6XtElIrT497bjs KonradHirschkorn"
        ];
      };
    };
    userBackupDirs = ["Coding" "Desktop" "Documents" "Pictures" "Videos" "Music" "Public" "Templates"];
    userDotFiles = [".config" ".mozilla" ".bash_history" ".steam" ".vscode-server" ".npm" ".vscode" ".local/share/kicad"];
    systemFiles = ["/var/lib/homeassistant"];
    backupPaths = builtins.concatLists (builtins.map (
      username: let
        h = "/home/${username}/";
      in
        (map (dir: "${h}${dir}") userBackupDirs)
        ++ (map (dir: "${h}${dir}") userDotFiles)
        ++ systemFiles
    ) (builtins.attrNames users));
  in {
    mkSystem = {
      hostFile,
      system,
      disks ? null,
      hostName
    }:
      nixpkgs-stable.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit
            disks
            inputs
            system
            home-manager
            #adwaita_hypercursor
            self
            nixos-raspberrypi
            users
            hostName
            hostIps
            backupPaths;

          # This node’s own IP
          ip = hostIps.${hostName};
        };

        modules = [
          disko.nixosModules.disko
          flatpaks.nixosModule
          vscode-server.nixosModules.default
          (import hostFile)
        ];
      };

    nixosConfigurations = {
      konrad-laptop = self.mkSystem {
        hostFile = ./hosts/konrad-laptop.nix;
        system = "x86_64-linux";
        disks = ["/dev/nvme0n1"];
        hostName = "konrad-laptop";
      };

      konrad-pc = self.mkSystem {
        hostFile = ./hosts/konrad-pc.nix;
        system = "x86_64-linux";
        disks = ["/dev/nvme0n1" "/dev/nvme1n1"];
        hostName = "konrad-pc";
      };

      konrad-server = self.mkSystem {
        hostFile = ./hosts/konrad-server.nix;
        system = "x86_64-linux";
        disks = ["/dev/sda"];
        hostName = "konrad-server";
      };

      konrad-wsl = self.mkSystem {
        hostFile = ./hosts/konrad-wsl.nix;
        system = "x86_64-linux";
        hostName = "konrad-wsl";
      };

      konrad-pi4 = self.mkSystem {
        hostFile = ./hosts/rpi4.nix;
        system = "aarch64-linux";
        hostName = "konrad-pi4";
      };

      greeter = self.mkSystem {
        hostFile = ./hosts/greeter.nix;
        system = "x86_64-linux";
        disks = ["/dev/sda"];
        hostName = "greeter";
      };

      homeassistant-yellow = let
        hostName = "homeassistant-yellow";
      in
        nixos-raspberrypi.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            {
              imports = with nixos-raspberrypi.nixosModules; [
                raspberry-pi-5.base
                raspberry-pi-5.bluetooth
              ];
            }
            vscode-server.nixosModules.default
            ./hosts/homeassistant-yellow.nix
            ({
              config,
              pkgs,
              lib,
              ...
            }: {
              system.nixos.tags = let
                cfg = config.boot.loader.raspberryPi;
              in [
                "raspberry-pi-${cfg.variant}"
                cfg.bootloader
                config.boot.kernelPackages.kernel.version
              ];
            })
          ];

          specialArgs = {
            hostName = hostName;
            backupPaths = backupPaths;
            system = "aarch64-linux";
            inherit inputs home-manager adwaita_hypercursor self nixos-raspberrypi users hostIps;
          };
        };

      installer = let
        system = "x86_64-linux";
        pkgs = import nixpkgs-stable {inherit system;};
        hosts = ["konrad-laptop" "konrad-pc" "konrad-server" "greeter"];
        hostDisks = {
          "konrad-laptop" = ["/dev/nvme0n1"];
          "konrad-pc" = ["/dev/nvme0n1" "/dev/nvme1n1"];
          "konrad-server" = ["/dev/sda"];
          "greeter" = ["/dev/sda"];
        };
      in
        nixpkgs-stable.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit self inputs hosts hostDisks home-manager adwaita_hypercursor users;
          };
          modules = [
            disko.nixosModules.disko
            vscode-server.nixosModules.default
            ({
              pkgs,
              lib,
              inputs,
              ...
            }: {
              imports = [
                (import ./common/installer.nix {
                  inherit pkgs self lib hosts hostDisks home-manager adwaita_hypercursor;
                })
              ];
            })
          ];
        };
    };
  };
}
