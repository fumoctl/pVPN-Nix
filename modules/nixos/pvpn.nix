{ config, lib, pkgs, ... }:

let
  cfg = config.programs.pvpn;
  inherit (lib) mkIf mkOption mkPackageOption types;

  defaultPackage = pkgs.callPackage ../../pkgs/pvpn.nix { };
  packageSet = if pkgs ? pvpn then pkgs else pkgs // { pvpn = defaultPackage; };
in
{
  options.programs.pvpn = {
    enable = lib.mkEnableOption "pVPN";

    package = mkPackageOption packageSet "pvpn" { nullable = true; };

    users = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Usernames to add to the "pvpn" group, which is needed
        to interact with the pVPN daemon.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = mkIf (cfg.package != null) [ cfg.package ];

    users.groups.pvpn.members = cfg.users;

    systemd.services.pvpnd = {
      description = "pVPN Daemon - Proton VPN Connection Manager";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        Environment = "HOME=/var/lib/pvpn";
        ExecStart = mkIf (cfg.package != null) (lib.getExe' cfg.package "pvpnd");
        Restart = "on-failure";
        RestartSec = 5;
        RuntimeDirectory = "pvpn";
        StateDirectory = "pvpn";
        StateDirectoryMode = "0700";
        ReadWritePaths = [
          "/run/pvpn"
          "/etc/resolv.conf"
          "/etc/pvpn"
          "/var/lib/pvpn"
        ];
        ProtectHome = true;
        PrivateTmp = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
      };
    };
  };
}
