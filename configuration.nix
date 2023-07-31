{ config, lib, pkgs, modulesPath, ... }:
let
  baseconfig = { allowUnfree = true; };

  stable = import <nixpkgs> { config = baseconfig; };
  unstable = import <nixpkgs-unstable> { config = baseconfig; };

  comma = (import (pkgs.fetchFromGitHub {
    owner = "nix-community";
    repo = "comma";
    rev = "v1.7.1";
    sha256 = "sha256-x2HVm2vcEFHDrCQLIp5QzNsDARcbBfPdaIMLWVNfi4c=";
  })).default;

in {
  imports = [
    ./hardware-configuration.nix
    (modulesPath + "/profiles/all-hardware.nix")

    <nixos-hardware/common/pc/ssd>
    <nixos-hardware/common/cpu/intel>

    # Service configuration.
    ./o11y.nix
    ./tailscale.nix
    ./containers.nix
  ];

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      unstable.intel-compute-runtime
      stable.intel-ocl
      stable.intel-media-driver
      stable.vaapiIntel
      stable.vaapiVdpau
      stable.libvdpau-va-gl
    ];
  };

  boot = {
    # Use the systemd-boot EFI boot loader.
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # Latest Linux kernel
    kernelPackages = unstable.linuxPackages_latest;

    kernelModules = [ "tcp_bbr" "kvm-intel" ];
    kernel.sysctl."net.ipv4.tcp_congestion_control" = "bbr";
    kernel.sysctl."net.core.default_qdisc" = "fq";
    tmp.cleanOnBoot = true;

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
      checkReversePath = "loose";
      trustedInterfaces = [ "tailscale0" "eno1" ];
      allowedUDPPorts = [ 443 config.services.tailscale.port 51413 4001 ];
      allowedTCPPorts = [ 22 53 80 443 51413 4001 8080];
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
    extraGroups =
      [ "wheel" "sudo" "oci" "docker" "root" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE/Cr+bIMxMzkk8dN7xxRsaJeHRifwlyTuh/ja9Uy9MN"
    ];
  };

  nix = {
    # Automatic Nix GC.
    gc = {
      automatic = true;
      dates = "04:00";
      options = "--delete-older-than 7d";
    };
    extraOptions = ''
      min-free = ${toString (500 * 1024 * 1024)}
    '';

    settings = {
      trusted-users = [ "root" "adi" ];
      # Automatic store optimization.
      auto-optimise-store = true;
    };
  };

  system = {
    # Automatic upgrades.
    autoUpgrade.enable = true;
    autoUpgrade.allowReboot = true;

    stateVersion = "23.05";
  };

  environment = {
    # Put ~/bin in PATH.
    homeBinInPath = true;

    # Packages which should be installed on every machine.
    systemPackages = with pkgs; [
      comma
      unstable.direnv
      unstable.git
      unstable.go
      unstable.clinfo
      unstable.lshw
      unstable.htop
      unstable.iftop
      unstable.iotop
      unstable.intel-gpu-tools
      unstable.neofetch
      unstable.nixfmt
      unstable.ripgrep
      unstable.starship
      unstable.tailscale
      unstable.wget
      unstable.zsh
    ];
  };

  # Enable firmware updates when possible.
  hardware.enableRedistributableFirmware = true;

  # Enable Chrony
  services.chrony.enable = true;
  services.chrony.package = unstable.chrony;
  services.chrony.extraConfig = ''
    makestep 1.0 10
    hwtimestamp *
    rtcsync
  '';
  

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  programs.mosh = { enable = true; };

  # fstrim
  services.fstrim = { enable = true; };   

  # fwupd
  services.fwupd = {
    package = unstable.fwupd;
    enable = true;
  };

  security.sudo.wheelNeedsPassword = false;

  virtualisation.docker = {
    enable = true;
    package = unstable.docker;
    daemon.settings = {
      experimental = true;
      ipv6 = true;
      fixed-cidr-v6 = "2001:db8:1::/64";
      ip6tables = true;
      registry-mirrors = [ "https://mirror.gcr.io" ];
    };
  };

  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /persist *(rw,fsid=root,no_subtree_check)
  '';
  services.nfs.server.hostName = "100.122.68.5";
  systemd.services.nfs-server = {
    after = [ "tailscaled.service" ];
  };


  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      format = "$all";
    };
  };
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableBashCompletion = true;
    enableGlobalCompInit = true;
    syntaxHighlighting.enable = true;
    autosuggestions.enable = true;
    interactiveShellInit = ''
      eval "$(direnv hook zsh)"
    '';
  };
}
