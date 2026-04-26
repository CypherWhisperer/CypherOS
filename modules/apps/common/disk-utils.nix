{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkMerge [
    (lib.mkIf (config.cypher-os.apps.common.enable && config.cypher-os.apps.common.disk-utils.enable) {

      home.packages = with pkgs; [
        # ── VENTOY   ─────────────────────────────────────────────────────────────
        ventoy
        #ventoy-full
        #ventoy-full-qt  # GUI supported qt version
        #ventoy-full-gtk # GUI supported gtk version
        exfatprogs # exFAT filesystem userspace utilities
        dosfstools # Utilities for creating and checking FAT and VFAT file systems
        ntfs3g # FUSE-based NTFS driver with full write support
        parted # Create, destroy, resize, check, and copy partitions
        util-linux # Set of system utilities for Linux
        usbutils # Tools for working with USB devices, such as lsusb
        pciutils # Programs 4 inspecting & manipulating PCI devices configuration
      ];
    })

    (lib.mkIf
      (
        config.cypher-os.apps.common.enable
        && config.cypher-os.apps.common.disk-utils.enable
        && config.cypher-os.profile.desktop.enable
      )
      {
        # GUI disk utilities that only make sense in a desktop environment.
        home.packages = with pkgs; [
          gparted # Graphical disk partitioning tool
        ];
      }
    )
  ];
}
