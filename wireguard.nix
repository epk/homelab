{ pkgs, lib, ... }: {
  # enable NAT
  networking.nat.enable = true;
  networking.nat.externalInterface = "eno1";
  networking.nat.internalInterfaces = [ "wg0" ];
  networking.firewall = { allowedUDPPorts = [ 51820 ]; };

  networking.wireguard.interfaces = {
    # "wg0" is the network interface name. You can name the interface arbitrarily.
    wg0 = {
      # Determines the IP address and subnet of the server's end of the tunnel interface.
      ips = [ "10.0.69.1/24" ];

      # The port that WireGuard listens to. Must be accessible by the client.
      listenPort = 51820;

      # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
      # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
      postSetup = ''
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.0.69.0/24 -o eno1 -j MASQUERADE
      '';

      # This undoes the above command
      postShutdown = ''
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.0.69.0/24 -o eno1 -j MASQUERADE
      '';

      privateKeyFile = "/home/adi/wireguard-keys/private";

      peers = [ ];
    };
  };
}
