{ lib, config, ... }:

{
  imports = [ ./options.nix ];

  config =
    lib.mkIf
      (config.cypher-os.apps.productivity.enable && config.cypher-os.apps.productivity.affine.enable)
      {
        networking.hosts = {
          "127.0.0.1" = [ "affine.local" ];
        };

        security.pki.certificateFiles = [
          /home/cypher-whisperer/DATA/FILES/DE_FILES/SHARED/APPS/affine/NEW_SCHOOL/PERSISTENT_DATA/caddy/data/caddy/pki/authorities/local/root.crt
        ];
      };
}
