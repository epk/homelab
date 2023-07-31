{ config, lib, pkgs, ... }:

let

  baseconfig = { allowUnfree = true; };
  unstable = import <nixpkgs-unstable> { config = baseconfig; };

in {

  services.tailscale = {
    enable = true;
    package = unstable.tailscale;
  };
  imports = [
    (fetchTarball
      "https://github.com/msteen/nixos-vscode-server/tarball/master")
  ];

  services.vscode-server.enable = true;
  environment.systemPackages = [ unstable.vscode-extensions.mkhl.direnv ];
}
