{
  lib,
  config,
  pkgs,
  ...
}:

let
  ctpLO = pkgs.fetchurl {
    # Catppuccin Mocha Mauve .soc
    url = "https://github.com/catppuccin/libreoffice/raw/main/themes/mocha/mauve/catppuccin-mocha-mauve.soc";
    sha256 = lib.fakeHash;
  };

{
  config =
    lib.mkIf
      (config.cypher-os.apps.productivity.enable && config.cypher-os.apps.productivity.libreOffice.enable)
      {
        home.packages = with pkgs; [
          # ── Office Suite ───────────────────────────────────────────────────────
          libreoffice
        ];

        home.file.".config/libreoffice/4/user/config/catppuccin-mocha-mauve.soc".source = ctpLO;
  };
}
