{ ... }:

{
  virtualisation.oci-containers = {
    containers = {
      #      grafana-agent = {
      #        autoStart = true;
      #        image = "grafana/agent:v0.24.0";
      #        cmd = ["-server.http.address=0.0.0.0:9100" "-config.file=/etc/agent/agent.yaml"];
      #        ports = [ "9100:9100/tcp" ];
      #        extraOptions = ["--pid=host" "--net=o11y"];
      #        volumes = [
      #          "/etc/grafana-agent/agent.yaml:/etc/agent/agent.yaml"
      #          "/etc/grafana-agent/data:/etc/agent/data"
      #          "/:/host:ro,rslave"
      #        ];
      #      };

      # ca-advisor = {
      #   autoStart = true;
      #   image = "gcr.io/cadvisor/cadvisor:v0.44.0";
      #   cmd = [ "--disable_metrics=percpu" "--docker_only=true" ];
      #   extraOptions = [ "--device=/dev/kmsg" "--privileged" "--net=o11y" ];
      #   ports = [ "8080:8080/tcp" ];
      #   volumes = [
      #     "/:/rootfs:ro"
      #     "/var/run:/var/run:ro"
      #     "/sys:/sys:ro"
      #     "/var/lib/docker/:/var/lib/docker:ro"
      #     "/dev/disk/:/dev/disk:ro"
      #   ];
      # };

      transmission = {
        autoStart = true;
        image = "lscr.io/linuxserver/transmission";
        extraOptions = [ "-e TZ=America/Vancouver" "-e TRANSMISSION_WEB_HOME=/combustion-release/"];
        ports = [ "9091:9091/tcp" "51413:51413/udp" "51413:51413" ];
        volumes = [
          "/var/lib/transmission/.config:/config"
          "/home/adi/Downloads:/downloads"
          "/home/adi/Downloads/watch:/watch"
        ];
      };

      jellyfin = {
        autoStart = true;
        image = "lscr.io/linuxserver/jellyfin";
        extraOptions = [ "-e TZ=America/Vancouver" "--device=/dev/dri:/dev/dri" ];
        ports = [ "8096:8096/tcp" ];
        volumes = [
          "/var/lib/jellyfin:/config"
          "/home/adi/Downloads/complete:/data/movies"
        ];
      };

    };
  };
}
