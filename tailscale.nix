{ config, lib, pkgs, ... }:

let

  baseconfig = { allowUnfree = true; };
  unstable = import <nixpkgs-unstable> { config = baseconfig; };

in {

  imports =
    [ <nixpkgs-unstable/nixos/modules/services/networking/tailscale.nix> ];
  disabledModules = [ "services/networking/tailscale.nix" ];

  nixpkgs.config = baseconfig // {
    packageOverrides = pkgs: { tailscale = unstable.tailscale; };
  };

  services.tailscale.enable = true;

}
