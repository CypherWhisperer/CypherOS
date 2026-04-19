{ config, pkgs, lib, ... }:

{
  options = {
    # Group-level gate — "do I want editors at all?"
    config.cypher-os.apps.editor.enable =
      lib.mkEnableOption "CypherOS Editor applications";
  };

  config = lib.mkIf (
    config.cypher-os.apps.enable &&
    config.cypher-os.apps.editor.enable ) {
      # Import the relevant modules.
      imports = [
        ./vim.nix
        ./neovim.nix
        ./vscode.nix
      ];

      # Turn on the individual editors. Child modules gate on their own options,
      # so these can be selectively overridden to false in configuration.nix.
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
