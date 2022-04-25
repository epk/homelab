{ config, pkgs, ... }:
let
  stable = import <nixpkgs> { };

  # Import comma with local nix-index preferred over the comma one.
  comma = import (builtins.fetchTarball
    "https://github.com/nix-community/comma/archive/refs/tags/1.1.0.tar.gz") {
      inherit pkgs;
    };

in {
  imports = [
    ./hardware-configuration.nix

    <nixos-hardware/common/pc/ssd>
    <nixos-hardware/common/cpu/intel>

    # Service configuration.
    ./containers.nix
    ./vscode-server.nix
    ./wireguard.nix
    ./o11y.nix
  ];

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      pkgs.intel-compute-runtime
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  boot = {
    # Use the systemd-boot EFI boot loader.
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # Linux kernel 5.15 LTS
    kernelPackages = stable.linuxPackages_5_15;

    kernelModules = [ "tcp_bbr" ];
    kernel.sysctl."net.ipv4.tcp_congestion_control" = "bbr";
    kernel.sysctl."net.core.default_qdisc" = "fq";
    cleanTmpDir = true;

    kernel.sysctl."net.ipv4.ip_forward" = 1;
    kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;
  };

  networking = {
    hostName = "servnerr";
    nameservers = [ "1.1.1.1" "2606:4700:4700::1111" ];

    useDHCP = false;
    interfaces.eno1.useDHCP = true;
    timeServers = [ "time.nrc.ca" "time.chu.nrc.ca" "time.google.com" ];

    firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
      allowedTCPPorts = [ 22 ];
    };
  };

  time.timeZone = "America/Vancouver";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.adi = {
    isNormalUser = true;
    extraGroups = [ "wheel" "sudo" "docker" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyjlZJ1nv50nYGs1s4sS+M3hKDg6GBM9bzAiB6RU5Cq"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFaaUnx1KDS6zsH4ADeumbZQsIkBWeGW/TCquzMjtg9T"
    ];
  };

  nix = {
    # Automatic Nix GC.
    gc = {
      automatic = true;
      dates = "04:00";
      options = "--delete-older-than 30d";
    };
    extraOptions = ''
      min-free = ${toString (500 * 1024 * 1024)}
    '';

    # Automatic store optimization.
    autoOptimiseStore = true;
  };

  system = {
    # Automatic upgrades.
    autoUpgrade.enable = true;
    autoUpgrade.allowReboot = true;

    stateVersion = "21.11";
  };

  environment = {
    # Put ~/bin in PATH.
    homeBinInPath = true;

    # Packages which should be installed on every machine.
    systemPackages = with pkgs; [
      bandwhich
      bind
      byobu
      comma
      conntrack-tools
      dmidecode
      ethtool
      bpftools
      linuxPackages.bpftrace
      gcc
      go
      git
      gitAndTools.gh
      gnumake
      htop
      iftop
      iperf3
      iptables
      jq
      lm_sensors
      lshw
      lsscsi
      mosh
      mkpasswd
      mtr
      ndisc6
      neofetch
      nethogs
      nixfmt
      nmap
      nmon
      pciutils
      pkg-config
      ripgrep
      smartmontools
      tailscale
      tcpdump
      tmux
      unixtools.xxd
      unzip
      usbutils
      wireguard-tools
      wget
      zsh
      python
    ];
  };

  # Enable firmware updates when possible.
  hardware.enableRedistributableFirmware = true;

  # Enable Chrony
  services.chrony.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  programs.mosh.enable = true;

  # Tailscale
  services.tailscale.enable = true;

  # fstrim
  services.fstrim.enable = true;
  
  # fwupd
  services.fwupd.enable = true;

  security.sudo.wheelNeedsPassword = false;
  virtualisation.docker = { enable = true; };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableBashCompletion = true;
    enableGlobalCompInit = true;
    syntaxHighlighting.enable = true;
    autosuggestions.enable = true;

    ohMyZsh = {
      enable = true;
      plugins = [ "git" "sudo" ];
      theme = "agnoster";
    };
  };
}
