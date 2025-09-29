{ pkgs, lib, modulesPath, ... }: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Boot faster
  boot.loader.timeout = lib.mkForce 2;

  # Enabling things for easy connectivity and for integration with Proxmox
  services.cloud-init.enable = true;
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
  };
  services.qemuGuest.enable = true;

  # For convenience of installation
  security.sudo.wheelNeedsPassword = false;
  environment.systemPackages = with pkgs; [
    nano
    git
    curl
    htop
  ];
}