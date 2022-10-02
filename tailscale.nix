{ config, lib, pkgs, ... }:
let
  baseconfig = { allowUnfree = true; };
  unstable = import <nixpkgs-unstable> { config = baseconfig; };
in {
  nixpkgs.overlays = [(final: prev: {
    tailscale = unstable.tailscale;
  })];

  services.tailscale.enable = true;
}

