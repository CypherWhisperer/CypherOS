# modules/devops/iac.nix
#
# NixOS module for Infrastructure as Code tooling.
#
# WHAT THIS FILE OWNS:
#   - Terraform (HashiCorp) and OpenTofu (open-source fork)
#   - Ansible (agentless configuration management)
#   - Pulumi (IaC in real programming languages)
#   - Supporting tools (tflint, terragrunt, ansible-lint)
#
# WHAT THIS FILE DOES NOT OWN:
#   - Terraform state files — managed by your backend (local, S3, Terraform Cloud)
#     and never committed to this repo
#   - Provider credentials — injected via environment variables or sops secrets
#   - Ansible inventory — lives in project repos, not in Nix config
#
# TERRAFORM vs OPENTOFU:
#   HashiCorp changed Terraform's license to BSL (Business Source License) in 2023.
#   OpenTofu is the Linux Foundation fork that maintained the original MPL-2.0 license.
#   They are functionally nearly identical today. Include both:
#     - terraform: you'll encounter it in every job/team context
#     - opentofu: the open-source future of the ecosystem
#   Use `tofu` as your default for personal projects; use `terraform` when working
#   on team projects that already use it.
#
# ENABLE:
#   devops.iac.enable = true;  in your host configuration.nix
#
# VERIFYING THE SETUP:
#   terraform version
#   tofu version
#   ansible --version
#   pulumi version
#   tflint --version

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
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (config.cypher-os.devops.enable && config.cypher-os.devops.iac.enable) {

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

      # ── OpenTofu ──────────────────────────────────────────────────────────────
      # The free, hydra-cache FOSS fork of Terraform.
      # Prefer this for new personal projects — it won't get relicensed.
      # Note: invoked as `tofu`, not `terraform`, to avoid PATH collision.
      # CLI is `tofu`. HCL syntax is compatible.
      # CLI: `tofu init`, `tofu plan`, `tofu apply`, `tofu destroy`
      opentofu

      # ── Supporting tools (all Hydra-cached) ──────────────────────────────
      # tenv: version manager for opentofu/terraform/terragrunt.
      # Allows pinning specific tool versions per project via .opentofu-version
      # or .terraform-version files. Useful when working with multiple projects
      # that require different opentofu versions.
      # CLI: `tenv tofu install 1.9.0`, `tenv tofu use 1.9.0`
      tenv

      # terraform-docs: generates documentation from .tf files.
      # Produces README tables of variables, outputs, and resources.
      # CLI: `terraform-docs markdown . > README.md`
      # terraform-docs

      # tflint: linter for Terraform/OpenTofu HCL files.
      # Catches errors and enforces best practices before apply.
      # CLI: `tflint --init && tflint`
      # tflint

      # ── Terragrunt ────────────────────────────────────────────────────────────
      # Thin wrapper around Terraform/OpenTofu that adds DRY configurations,
      # remote state management, and module composition. Used in large
      # infrastructure repos where copy-pasting Terraform blocks gets unwieldy.
      # Learn Terraform basics first; add Terragrunt when your configs repeat.
      terragrunt

      # ── TFLint ────────────────────────────────────────────────────────────────
      # Linter for Terraform/OpenTofu files. Catches errors and enforces best
      # practices before you `terraform apply`. Integrates with your editor's LSP.
      tflint

      # ── Ansible ───────────────────────────────────────────────────────────────
      # Agentless configuration management and orchestration. You describe desired
      # state in YAML playbooks; Ansible SSH's into machines and makes it so.
      # Contrast with Nix: Ansible is imperative per-task; Nix is declarative
      # per-system. In practice you'll use both — Nix for your own machines,
      # Ansible for heterogeneous fleets you don't own.
      # Usage: ansible-playbook playbook.yml -i inventory
      ansible

      # ansible-lint: linter for Ansible playbooks. Catches style issues,
      # deprecated syntax, and common mistakes. Good habit from the start.
      ansible-lint

      # ── Pulumi ────────────────────────────────────────────────────────────────
      # IaC using real programming languages (TypeScript, Python, Go, C#).
      # Instead of HCL, you write actual code with loops, conditionals, and
      # abstractions. Strong fit if you're already comfortable with TypeScript.
      # Pulumi programs compile down to the same cloud provider APIs as Terraform.
      # Usage: pulumi new typescript && pulumi up
      pulumi

      # ── DEFERRED ──────────────────────────────────────────────────────────────
      # terraform-ls: Terraform Language Server (LSP). Gives completion and
      # validation in Neovim. Install via mason.nvim in your CypherIDE config
      # rather than here — mason handles LSP server lifecycle better.
      # terraform-ls

      # checkov: static analysis for IaC security misconfigurations.
      # Scans Terraform, Ansible, Kubernetes manifests. Good CI gate.
      # Add when you have substantial IaC code to scan.
      # checkov
    ];

  };
}
