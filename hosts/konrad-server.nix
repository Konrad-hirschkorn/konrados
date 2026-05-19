{
  modulesPath,
  config,
  pkgs,
  inputs,
  home-manager,
  lib,
  disks,
  users,
  ...
}: {
  # Import basic configuration
  imports = [
    ../common/after_installer.nix
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    (import ../common/disko.nix {inherit disks;})
    ../common/common.nix
    ../packages/system-packages.nix
    ../packages/dependencies.nix
  ];

  # Standard user 'konrad'
  users.users.konrad = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "networkmanager" ];
    home = "/home/konrad";
    hashedPassword = users.konrad.hashedPassword;
    openssh.authorizedKeys.keys = users.konrad.authorizedKeys;
  };

  # OpenSSH Service
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # Basic Networking
  networking.networkmanager.insertNameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 25565 ];
    allowedUDPPorts = [];
    trustedInterfaces = ["docker0" "lo"];
    allowPing = true;
  };

  # Simple Minecraft Tunnel to IONOS
  systemd.services.minecraft-tunnel = {
    description = "SSH Reverse Tunnel for Minecraft Server";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      User = "konrad";
      ExecStart = ''
        ${pkgs.openssh}/bin/ssh -N -R 0.0.0.0:25565:localhost:25565 -o ServerAliveInterval=60 -o ExitOnForwardFailure=yes root@82.165.143.27
      '';
      Restart = "always";
      RestartSec = "10";
    };
  };

  # Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "btrfs";

  # Minimal Containers
  virtualisation.oci-containers.containers = {
    minecraft-server = {
      image = "itzg/minecraft-server:latest";
      autoStart = true;
      ports = ["0.0.0.0:25565:25565"];
      volumes = ["/mnt/docker-data/volumes/minecraft:/data:rw"];
      environment = {
        EULA = "TRUE";
        VERSION = "LATEST";
        MEMORY = "12G";
      };
    };
  };
}
