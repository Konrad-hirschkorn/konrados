{
  config,
  pkgs,
  inputs,
  home-manager,
  lib,
  isDesktop,
  isWsl,
  isServer,
  isHomeAssistant,
  users,
  ...
}: let
in {
  # Import the Home Manager NixOS module
  imports = [
  ];

  # NixOS system-wide home-manager configuration
  home-manager.sharedModules = [
    inputs.sops-nix.homeManagerModules.sops
    (import ./common-home-manager.nix {
      inherit config pkgs inputs home-manager lib isDesktop isWsl isServer isHomeAssistant;
    })
  ];

  # Home Manager individual user configuration
  home-manager.users =
    lib.mapAttrs (
      _name: user: {
        lib,
        pkgs,
        ...
      }: (
        {
          home.stateVersion = "25.11";
          programs.git = {
            enable = true;
            settings = {
              user.name = user.gitUsername;
              user.email = user.gitEmail;
              init.defaultBranch = "main";
              safe.directory = ["/etc/nixos" "/tmp/NixOs"];
              pull.rebase = "true";
              push.autoSetupRemote = true;
              core.autocrlf = "input";
              core.eol = "lf";
            };
          };
        }
      )
    ) users;
}