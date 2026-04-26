# ARCHITECTURE DECISION — why opentofu, not terraform:
#   Terraform >= 1.6 uses the HashiCorp BSL license. Hydra does not build
#   BSL/unfree packages. The last Hydra binary was terraform-1.5.7 (Sept 2023).
#   There will NEVER be a cache.nixos.org binary for any terraform >= 1.6.
#
#   opentofu is the Linux Foundation fork of Terraform (forked from 1.5.x,
#   the last MPL-licensed version). It is:
#   - CLI-compatible: `tofu` replaces `terraform`. All .tf files work as-is.
#   - Built by Hydra: binaries available on cache.nixos.org — no source build.
#   - Actively maintained: releases track terraform feature parity closely.
#   - License: MPL 2.0 — fully free and open-source.
#
# WHY NOT DOCKER:
#   terraform/opentofu is a CLI TOOL, not a server. It runs, does its work,
#   and exits. Containerizing a CLI tool means: launch container → run command
#   → destroy container. This is how CI pipelines use it. On a developer
#   workstation it adds overhead with zero benefit. Install it directly.
#
# MIGRATION FROM TERRAFORM:
#   If you have existing .tf files:
#   1. Replace `terraform` with `tofu` in all commands
#   2. Run `tofu init` — it re-downloads providers
#   3. Everything else is identical
#   For provider lock files (.terraform.lock.hcl), run `tofu providers lock`
#   to regenerate them with opentofu-compatible hashes.
# =============================================================================

{
  config,
  lib,
  pkgs,
  ...
}:

{
  config =
    lib.mkIf (config.cypher-os.devops.iac.enable && config.cypher-os.devops.iac.terraform.enable)
      {
        environment.systemPackages = with pkgs; [
          # ── Terraform ─────────────────────────────────────────────────────────────
          # The industry-standard IaC tool. You will encounter this everywhere in
          # DevOps job contexts. HCL (HashiCorp Configuration Language) syntax.
          # Despite the license change, the ecosystem (providers, modules, tutorials)
          # is still overwhelmingly built around Terraform.
          # Usage: terraform init && terraform plan && terraform apply
          #
          # last successful build: terraform-1.5.7 in September 2023, which is exactly
          # the last MPL-licensed version before the BSL switch. This confirms:
          # Hydra (NixOS's CI system) stopped building terraform the moment it went unfree.
          # No binary will ever appear for terraform ≥ 1.6 on cache.nixos.org.
          #
          # No third-party cache (including the terraform-cachix) reliably covers
          # nixos-unstable's current revision. There is a path for opentofu.
          # It is CLI-compatible, Hydra builds it, and you get a binary. Make this switch now.
          #
          # Build vault in isolation — one job, two cores, explicitly allow the source build.
          # Do this when the machine is idle
          #      nix build nixpkgs#vault \
          #        --option max-jobs 1 \
          #        --option cores 2 \
          #        --option fallback true \
          #        --option sandbox true
          #
          # It does require allowUnfree to be true, otherwise NixOS will refuse to build.
          terraform

          # ── DEFERRED ──────────────────────────────────────────────────────────────
          # terraform-ls: Terraform Language Server (LSP). Gives completion and
          # validation in Neovim. Install via mason.nvim in your CypherIDE config
          # rather than here — mason handles LSP server lifecycle better.
          # terraform-ls
        ];
      };
}
