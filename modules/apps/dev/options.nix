{ lib, ... }:

{
  options.cypher-os.apps.dev = {
    enable = lib.mkEnableOption "CypherOS development environment";
    git.enable = lib.mkEnableOption "Git Version Control System";
    ssh.enable = lib.mkEnableOption "Enable SSH client configuration";
    devenv.enable = lib.mkEnableOption "Enable devenv + direnv project shell tooling";
  };
}
