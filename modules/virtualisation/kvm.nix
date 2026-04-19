
# ─────────────────────────────────────────────────────────────────────────────
# VIRTUALISATION — KVM / QEMU / libvirt
# ─────────────────────────────────────────────────────────────────────────────
# libvirt: the daemon virt-manager talks to. Manages QEMU VMs via D-Bus.
# FUTURE EXTRACTION NOTE:
#   This block is a candidate for modules/virtualisation/kvm.nix.
#   When the modularization pass reaches here, extract it and replace this
#   block with: virtualisation.kvm.enable = true;
#   See modules/virtualisation/default.nix for the extraction checklist.

{ config, pkgs, lib, ... }:

{
  options = {
    cypher-os.virtualisation.helpers.kvm = {
      enable = lib.mkEnableOption "Enable KVM/QEMU virtualization";
    };
  };

  config = lib.mkIf config.cypher-os.virtualisation.helpers.kvm.enable {

    environment.systemPackages = with pkgs; [
      # VIRTUALIZATION (system-level GUI tools)
      # virt-manager: the standard GUI for managing KVM/QEMU VMs on Linux.
      # Lives here - an imported in configuration.nix (not in virtualisation/default.nix)
      # because it needs access to the libvirtd socket which is a system-level service.
      virt-manager
      # CLI tools for working with disk images (qemu-img, qemu-nbd, etc.)
      qemu-utils
    ];

    virtualisation.libvirtd = {
      # libvirt: the daemon virt-manager talks to
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm; # QEMU compiled specifically with KVM enabled.
        # Alternatives (uncomment to override):
        #qemu_full #  includes everything (all emulation targets, all frontends)
        #qemu_xen  # Xen hypervisor variant. If you're running a Xen setup.
        #qemu-user # userspace emulation only; for cross-compilation,not VM hosting
        # Python bindings and QMP protocol tools. Only needed if you're scripting VM management programmatically.
        #qemu-python-utils
        #python313Packages.qemu
        #python313Packages.qemu-qmp
      };
    };
  };
}
