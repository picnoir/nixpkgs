{config, pkgs, lib, ...}:

with lib;

let

  cfg = config.services.guix;
  rsync = "${pkgs.rsync}/bin/rsync";

  buildGuixUser = i:
    {
      "guixbuilder${builtins.toString i}" = {
        group = "guixbuild";
        extraGroups = ["guixbuild"];
        home = "/var/empty";
        shell = pkgs.nologin;
        description = "Guix build user ${builtins.toString i}";
        isSystemUser = true;
      };
    };

  bootstrap-guix-paths = pkgs.writeScriptBin "bootstrap-guix-paths" ''
      #!/usr/bin/env bash

      # We do not want to run this script on earch service start, we
      # only want to run it if the guix nix package has been updated,
      # meaning a new guix bootstrap store needs to merged to the
      # existing one.
      #
      # We're using the /var/guix/guix_nix_store_path file to track
      # the guix nix store path we had the last time we ran this
      # script. If the path changed, we need to update the bootstrap
      # store and the default substitutes. If it didn't, this script
      # should be no-op.

      latestGuixKnownPath="/var/guix/guix_nix_store_path"
      if ! [[ -f "''${latestGuixKnownPath}" ]] || ! grep -q "${pkgs.guix}" "''${latestGuixKnownPath}"
        then
          # Merging both the store and the /var/guix coming from the
          # package to the current system.
          ${rsync} -a --ignore-existing ${cfg.package.store}/gnu/store /gnu/

          # We set $GUIX_PROFILE to use the /root/../current instead of
          # the one embedded in the guix store path of the guix binary.
          GUIX_PROFILE="/root/.config/guix/current"; source $GUIX_PROFILE/etc/profile
          # authorize substitutes
          guix archive --authorize < /root/.config/guix/current/share/guix/ci.guix.info.pub
          echo ${pkgs.guix} > "''${latestGuixKnownPath}"
      fi
  '';


in {

  options.services.guix = {
    enable = mkEnableOption "GNU Guix package manager";
    package = mkOption {
      type = types.package;
      default = pkgs.guix;
      defaultText = "pkgs.guix";
      description = "Package that contains the guix binary and initial store.";
    };
  };

  config = mkIf (cfg.enable) {

    users = {
      extraUsers = lib.fold (a: b: a // b) {} (builtins.map buildGuixUser (lib.range 1 10));
      extraGroups.guixbuild = {name = "guixbuild";};
    };

    systemd.tmpfiles.rules = [
      #t  path                                            user gr   Age Arg
      "d  '/gnu/store'                                    root root -   -"
      "d  '/root/.config/guix'                            root root -   -"
      "d  '/var/guix/gcroots'                             root root -   -"
      "L+ '/var/guix/gcroots/profiles                     root root -  '${guix.var}/var/guix/gcroots/profiles'"
      "d  '/var/guix/gprofiles/per-user/root'             root root -   -"
      "L+ '/var/guix/profiles/per-user/root/current-guix' root root -  '${guix.var}/var/guix/profiles/per-user/root/current-guix'"
      "L+ '/root/.config/guix/current'                    root root -  '${guix.var}/var/guix/profiles/per-user/root/current-guix'"
    ];

    systemd.services.guix-daemon = {
      enable = true;
      description = "Build daemon for GNU Guix";
      serviceConfig = {
        ExecStartPre = "${bootstrap-guix-paths}/bin/boostrap-guix-paths";
        ExecStart="/var/guix/profiles/per-user/root/current-guix/bin/guix-daemon --build-users-group=guixbuild";
        Environment="GUIX_LOCPATH=/var/guix/profiles/per-user/root/guix-profile/lib/locale";
        RemainAfterExit="yes";

        # See <https://lists.gnu.org/archive/html/guix-devel/2016-04/msg00608.html>.
        # Some package builds (for example, go@1.8.1) may require even more than
        # 1024 tasks.
        TasksMax="8192";
      };
      wantedBy = [ "multi-user.target" ];
    };

    environment.shellInit = ''
      # Make the Guix command available to users
      export PATH="/var/guix/profiles/per-user/root/current-guix/bin:$PATH"
      export GUIX_LOCPATH="$HOME/.guix-profile/lib/locale"
      export PATH="$HOME/.guix-profile/bin:$PATH"
      export INFOPATH="$HOME/.guix-profile/share/info:$INFOPATH"
    '';
  };

}
