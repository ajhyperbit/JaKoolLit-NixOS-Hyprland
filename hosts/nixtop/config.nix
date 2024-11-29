# Main default config

{ config, pkgs, host, username, options, lib, inputs, system, ...}: 

lib.mkMerge [

let
  host = "nixtop";
  
  inherit (import ./variables.nix) keyboardLayout;
  python-packages = pkgs.python3.withPackages (
    ps:
      with ps; [
        requests
        pyquery # needed for hyprland-dots Weather script
        ]
  );
  
  in {
  imports = [
    ./hardware.nix
    ./users.nix
    ../../hosts/common/common.nix
    #../../modules/amd-drivers.nix
    #../../modules/nvidia-drivers.nix
    #../../modules/nvidia-prime-drivers.nix
    ../../modules/intel-drivers.nix
    #../../modules/vm-guest-services.nix
  ];

  # BOOT related stuff
  boot = {
    #kernelPackages = pkgs.linuxPackages_latest; # Kernel

    kernelParams = [
    ];
    initrd = { 
      availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" "uas" "thunderbolt"];
      kernelModules = [ ];
    };
      kernelModules = [ "kvm-intel" ];
  };

  drivers.intel.enable = true;

  services = {
  };

  environment= {
    #shellAliases = {
    #  google-chrome = "google-chrome-stable"
    #};
    variables = {
      #QT_STYLE_OVERRIDE = "breeze";
      #QT_QPA_PLATFORMTHEME= "qt5ct";
    };

    sessionVariables = {
    no_hardware_cursors = "true";
    #WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    #KDE_FULL_SESSION = "true";
    #GBM_BACKEND = "nvidia-drm";
    #LIBVA_DRIVER_NAME = "nvidia";
    #__GLX_VENDOR_LIBRARY_NAME = "nvidia";
    #QT_QPA_PLATFORM = "wayland;xcb";
    #QT_QPA_PLATFORMTHEME= "qt5ct";
    #GDK_BACKEND = "wayland,x11,*";
    #NVD_BACKEND = "direct";
  };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
]