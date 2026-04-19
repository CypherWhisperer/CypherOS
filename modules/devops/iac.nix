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

{ config, pkgs, lib, ... }:

{
  # ── Module Option ────────────────────────────────────────────────────────────
  options.cypher-os.devops.iac.enable = lib.mkEnableOption
    "Infrastructure as Code tooling (Terraform, OpenTofu, Ansible, Pulumi)";

  config = lib.mkIf config.cypher-os.devops.iac.enable {

    environment.systemPackages = with pkgs; [

      # ── Terraform ─────────────────────────────────────────────────────────────
      # The industry-standard IaC tool. You will encounter this everywhere in
      # DevOps job contexts. HCL (HashiCorp Configuration Language) syntax.
      # Despite the license change, the ecosystem (providers, modules, tutorials)
      # is still overwhelmingly built around Terraform.
      # Usage: terraform init && terraform plan && terraform apply
      terraform

      # ── OpenTofu ──────────────────────────────────────────────────────────────
      # The FOSS fork of Terraform. CLI is `tofu`. HCL syntax is compatible.
      # Prefer this for new personal projects — it won't get relicensed.
      # Note: invoked as `tofu`, not `terraform`, to avoid PATH collision.
      opentofu

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
