{ config, pkgs, lib, ... }:

{
  config = lib.mkIf (
    config.cypher-os.apps.enable &&
    config.cypher-os.apps.editor.enable ) {
      cypher-os.apps.editor.vim.enable = lib.mkDefault true;
      cypher-os.apps.editor.neovim.enable = lib.mkDefault true;
      cypher-os.apps.editor.vscode.enable = lib.mkDefault true;

      # Install other editors that don't need options or modules.
      home.packages = with pkgs; [
        # ── Editors & IDEs ───────────────────────────────────────────────────────
        antigravity
        #antigravity-fhs
        code-cursor
        jetbrains.webstorm
        android-studio # bare install — configure SDK via UI. (bundles emulator, SDK manager, AVD manager)
      ];
  };
}
