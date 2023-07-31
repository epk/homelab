{ ... }:

{
  virtualisation.oci-containers = {
    backend = "docker";

    containers = {
      watchtower = {
        autoStart = true;
        image = "containrrr/watchtower:latest";
        volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
        extraOptions = [ "--network=internal-network" ];
      };

      envoy = {
        autoStart = true;
        image = "envoyproxy/envoy:v1.27-latest";
        cmd = [
          "--config-path /etc/envoy/envoy.yaml"
          "--drain-time-s 30"
          "--drain-strategy immediate"
          "--cpuset-threads"
          "--disable-hot-restart"
        ];
        volumes = [
          "/persist/envoy/envoy.yaml:/etc/envoy/envoy.yaml"
          "/persist/certbot-cloudflare/letsencrypt:/etc/letsencrypt"
        ];
        environment = {
          "ENVOY_UID" = "0";
          "ENVOY_GID" = "0";
        };
        ports = [ "80:80" "443:443" "9901:9901" "443:443/udp" ];
        extraOptions = [ "--network=internal-network" ];
      };

      code-server = {
        dependsOn = [ "envoy" ];

        autoStart = true;
        image = "lscr.io/linuxserver/code-server:latest";
        volumes = [
          "/persist/code-server:/config"
          "/persist:/persist"
          "/home/adi:/home/adi"
          "/etc/nixos:/etc/nixos"
        ];
        environment = {
          PGID = "1000";
          PUID = "1000";
        };
        extraOptions = [ "--network=internal-network" ];
      };

      homebridge = {
        autoStart = true;

        image = "oznu/homebridge:latest";
        volumes = [ "/persist/homebridge:/homebridge" ];
        environment = {
          PGID = "1000";
          PUID = "1000";
        };
        extraOptions = [ "--network=host" ];
      };

      wireguard = {
        autoStart = true;
        image = "linuxserver/wireguard:1.0.20210914";
        volumes = [
          "/persist/mullvad/wg0.conf:/config/wg0.conf"
          "/lib/modules:/lib/modules"
        ];
        environment = {
          PGID = "1000";
          PUID = "1000";
        };
        extraOptions = [
          "--net=internal-network"
          "--cap-add=NET_ADMIN"
          "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
          "--sysctl=net.ipv6.conf.all.disable_ipv6=1"
        ];
      };

      transmission = {
        dependsOn = [ "wireguard" ];

        autoStart = true;
        image = "linuxserver/transmission:latest";
        volumes = [
          "/persist/transmission:/config"
          "/persist/downloads:/downloads"
          "/persist/downloads/torrent-watch:/watch"
        ];
        environment = {
          PGID = "1000";
          PUID = "1000";
          TR_CURL_SSL_NO_VERIFY = "1";
        };
        extraOptions = [
          "--net=container:wireguard"
          "--sysctl=net.ipv6.conf.all.disable_ipv6=1"
        ];
      };

      plex = {
        dependsOn = [ "envoy" ];

        autoStart = true;
        image = "lscr.io/linuxserver/plex:latest";
        volumes = [
          "/persist/plex:/config"
          "/persist/downloads/tvshows:/data/tvshows"
          "/persist/downloads/movies:/data/movies"
        ];
        environment = {
          PGID = "1000";
          PUID = "1000";
          VERSION = "docker";
        };
        extraOptions =
          [ "--network=internal-network" "--device=/dev/dri:/dev/dri" ];
      };

      jellyfin = {
        dependsOn = [ "envoy" ];

        autoStart = true;
        image = "lscr.io/linuxserver/jellyfin:latest";
        volumes = [
          "/persist/jellyfin:/config"
          "/persist/downloads/tvshows:/data/tvshows"
          "/persist/downloads/movies:/data/movies"
        ];
        environment = {
          PGID = "1000";
          PUID = "1000";
        };
        extraOptions =
          [ "--network=internal-network" "--device=/dev/dri:/dev/dri" ];
      };
    };
  };
}
