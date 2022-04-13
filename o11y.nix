{ pkgs, lib, ... }:

let
  fromYAML = yaml:
    builtins.fromJSON (builtins.readFile (pkgs.runCommand "from-yaml" {
      inherit yaml;
      allowSubstitutes = false;
      preferLocalBuild = true;
    } ''
      ${pkgs.remarshal}/bin/remarshal  \
        -if yaml \
        -i <(echo "$yaml") \
        -of json \
        -o $out
    ''));

  readYAML = path: fromYAML (builtins.readFile path);
in {
  services.promtail = {
    enable = true;
    configuration = readYAML ("/etc/promtail/config.yaml");
  };
}
