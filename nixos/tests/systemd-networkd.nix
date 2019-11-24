# What we wanna test:
# NetDev:
# [ ] vlan
# [ ] vrf
# [x] wireguard
# [ ] bond
#
# Network:
# (link)
# [ ] MACAddress # single
# [ ] MTUBytes # single
# [ ] Unmanaged # single
# (network)
# [ ] DHCP # router
# [ ] DHCPServer # router
# [ ] Address # single
# [ ] Gateway # router
# [ ] DNS # single
# [ ] IPForward # router
# [ ] IPMasquerade??? # router
# [ ] IPv6PrivacyExtensions # single
# [ ] IPv6AcceptRA # router
# [ ] VRF # router
# [ ] VLAN # router
# (address)
# [ ] Address # single
# [ ] Scope # ??
# (route)
# [ ] Gateway # router
# [ ] GatewayOnLink # router
# [ ] Destination # router
# [ ] Source # router
# [ ] Metric # router
# [ ] Table # router
# [ ] Type # router
# (dhcpserver)
# [ ] EmitDNS # router
# [ ] EmitNTP # routre
# [ ] EmitTimeZone # router
# (ipv6prefixDelegation) # routre
# [ ] RouterLifetimeSec
# [ ] RouterPreference
# [ ] Managed
# [ ] EmitDNS
# [ ] EmitDomains
# (routingPolicyRule: TODO: add the options) # router
# [ ] From
# [ ] To
# [ ] firewallMark
# [ ] Table
# [ ] IncomingInterface
# [ ] OutgoingInterface
# [ ] SourcePort
# [ ] DestinationPort
# [ ] IPProtocol
# [ ] InvertRule

let generateWireguardConf = import ./systemd-networkd/generateWireguardConf.nix;
in import ./make-test-python.nix ({pkgs, ... }: {
  name = "networkd-wireguard";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ ninjatrappeur ];
  };
  nodes = {
    wgNode1 = { pkgs, config, ... }:
    let localConf = {
        inherit pkgs config;
        privkpath = pkgs.writeText "priv.key" "GDiXWlMQKb379XthwX0haAbK6hTdjblllpjGX0heP00=";
        pubk = "iRxpqj42nnY0Qz8MAQbSm7bXxXP5hkPqWYIULmvW+EE=";
        nodeId = "1";
        peerId = "2";
    };
    in generateWireguardConf localConf;

    wgNode2 = { pkgs, config, ... }:
    let localConf = {
        inherit pkgs config;
        privkpath = pkgs.writeText "priv.key" "eHxSI2jwX/P4AOI0r8YppPw0+4NZnjOxfbS5mt06K2k=";
        pubk = "27s0OvaBBdHoJYkH9osZpjpgSOVNw+RaKfboT/Sfq0g=";
        nodeId = "2";
        peerId = "1";
    };
    in generateWireguardConf localConf;
  };
testScript = ''
    start_all()
    for n in [wgNode1, wgNode2]:
        n.wait_for_unit("systemd-networkd-wait-online.service")
    wgNode1.succeed("ping -c 5 10.0.0.2")
    wgNode2.succeed("ping -c 5 10.0.0.1")
    # Is the fwmark set?
    wgNode2.succeed("wg | grep -q 42")
'';
})
