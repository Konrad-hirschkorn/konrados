{ disks, config, pkgs, ... }:

{
  imports = [
    (import ../common/disko.nix { inherit disks; })
    ./desktop-only-imports.nix
    ./konrad-laptop-hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  users.users.konrad = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    home = "/home/konrad";
  };

  hardware = {
    i2c.enable = true;

    bluetooth.settings.General = {
      Name = "konrad-Laptop";
      DisablePlugins = "hostname";
    };
  };

  # SOPS-Konfiguration: Definiere, welche Geheimnisse aus der secrets.yaml-Datei
  # extrahiert und im System verfügbar gemacht werden sollen.
  sops.secrets.test_secret = {
    # Pfad zur verschlüsselten Datei, relativ zur flake.nix
    sopsFile = ../secrets/secrets.yaml;
    # Der Name des Schlüssels in der YAML-Datei, dessen Wert wir extrahieren wollen.
    key = "test";
    # Optional: Ein Beispiel, wie man das Geheimnis verwenden kann.
    # Dieses Paket erstellt ein kleines Skript unter /run/current-system/sw/bin/show-secret
    # das den Wert des Geheimnisses ausgibt.
    owner = "konrad"; # Stellt sicher, dass der Benutzer 'konrad' die Datei lesen kann.
  };

}
