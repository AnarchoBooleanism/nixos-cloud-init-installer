{ pkgs, lib, modulesPath, ... }: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Boot faster
  boot.loader.timeout = lib.mkForce 2;

  # Enable serial console, for direct access
  boot.kernelParams = [
    "console=ttyS0,115200"
    "console=tty1"
  ];

  # Enabling things for easy connectivity and for integration with Proxmox, as well as other hypervisors
  services.cloud-init.enable = true;
  services.cloud-init.network.enable = true;
  networking.useDHCP = false; # cloud-init should handle this
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
  };
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
  virtualisation.virtualbox.guest.enable = lib.mkIf (pkgs.stdenv.hostPlatform.isx86_64) true; # Quick solution as VirtualBox doesn't support ARM
  virtualisation.hypervGuest.enable = true;

  # For convenience of installation/debugging
  security.sudo.wheelNeedsPassword = false;
  environment.systemPackages = with pkgs; [
    zsh
    tmux
    cloud-init
    nano
    vim
    neovim
    man-db
    tldr
    git
    curl
    rsync
    htop
    bash-completion
    dmidecode
    ncdu
    dig
    net-tools
    # More guest agents
    open-vm-tools
  ] ++ lib.optionals (pkgs.stdenv.hostPlatform.isx86_64) [ # Quick solution as Xen doesn't support ARM
    xen-guest-agent
  ];
}