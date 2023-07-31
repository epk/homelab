{ config, pkgs, lib, ... }:

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
  baseconfig = { allowUnfree = true; };
  unstable = import <nixpkgs-unstable> { config = baseconfig; };
in {
  services.promtail = {
    # package  = unstable.promtail;
    enable = true;
    configuration = readYAML ("/etc/promtail/config.yaml");
  };

  services.prometheus = {
    #package = unstable.prometheus;
    enable = true;
    port = 9001;
    extraFlags = [ "--web.route-prefix=/" ];
    remoteWrite = [{
      url = "https://prometheus-us-central1.grafana.net/api/prom/push";
    }];

    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
      };
      smokeping = {
        enable = true;
        hosts = [
          "10.0.0.1"
          "1.1.1.1"
          "8.8.8.8"
          "google.com"
          "cloudflare.com"
          "reddit.com"
          "twitter.com"
          "shopify.com"
          "amazon.com"
        ];
      };
    };

    scrapeConfigs = [
      {
        job_name = "integrations/node_exporter";
        scrape_interval = "10s";
        static_configs = [{
          targets = [
            "127.0.0.1:${
              toString config.services.prometheus.exporters.node.port
            }"
          ];
        }];
      }
      {
        job_name = "integrations/ping";
        scrape_interval = "10s";
        static_configs = [{
          targets = [
            "127.0.0.1:${
              toString config.services.prometheus.exporters.smokeping.port
            }"
          ];
        }];
      }
      {
        job_name = "integrations/envoy";
        scrape_interval = "10s";
        metrics_path = "/stats/prometheus";
        static_configs = [{ targets = [ "127.0.0.1:9901" ]; }];
      }
    ];
  };
}
