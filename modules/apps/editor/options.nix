{ lib, ... }:

{
  options.cypher-os.apps.editor = {
    enable = lib.mkEnableOption "CypherOS Editor applications";
    neovim.enable = lib.mkEnableOption "CypherOS Neovim editor";
    vim.enable = lib.mkEnableOption "CypherOS Vim editor";
    vscode.enable = lib.mkEnableOption "CypherOS VSCode editor configuration";
  };
}
