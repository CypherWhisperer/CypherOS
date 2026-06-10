{
  pkgs,
  lib,
  config,
  ...
}:

{
  config =
    lib.mkIf
      (config.cypher-os.apps.productivity.enable && config.cypher-os.apps.productivity.penpot.enable)
      {
        home.packages = with pkgs; [
          penpot-desktop
        ];

        # OPTIONAL: write a ~/.config/Penpot/ config file via home.file to pre-seed
        # my local instance URL declaratively
        # (possible but slightly fragile since Electron may overwrite it)

        # Handle any environment variables needed for
        # Wayland/X11, WebKit rendering flags, or GNOME integration
      };
}
