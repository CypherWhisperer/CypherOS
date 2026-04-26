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

{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [ terraform.nix ];
  config = lib.mkIf (config.cypher-os.devops.enable && config.cypher-os.devops.iac.enable) {

    environment.systemPackages = with pkgs; [
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
      terraform-docs

      # tflint: linter for Terraform/OpenTofu HCL files.
      # Catches errors and enforces best practices before apply.
      # CLI: `tflint --init && tflint`
      tflint

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
      # checkov: static analysis for IaC security misconfigurations.
      # Scans Terraform, Ansible, Kubernetes manifests. Good CI gate.
      # Add when you have substantial IaC code to scan.
      # checkov
    ];

  };
}
