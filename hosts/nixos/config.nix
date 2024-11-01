# Main default config

{ config, pkgs, host, username, options, lib, inputs, system, ...}: 

let
  
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
    #../../modules/amd-drivers.nix
    ../../modules/nvidia-drivers.nix
    #../../modules/nvidia-prime-drivers.nix
    #../../modules/intel-drivers.nix
    ../../modules/vm-guest-services.nix
    ../../modules/local-hardware-clock.nix
  ];

  # BOOT related stuff
  boot = {
    #kernelPackages = pkgs.linuxPackages_latest; # Kernel

    kernelParams = [
    "systemd.mask=systemd-vconsole-setup.service"
    "systemd.mask=dev-tpmrm0.device" #this is to mask that stupid 1.5 mins systemd bug
    "nowatchdog" 
    #"modprobe.blacklist=sp5100_tco" #watchdog for AMD
    #"modprobe.blacklist=iTCO_wdt" #watchdog for Intel
    "nohibernate"
    "amd_iommu=on"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];
    tmp.cleanOnBoot = true;
    #supportedFilesystems = ["ntfs"];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      #grub = {
      #  device = "nodev";
      #  efiSupport = true;
      #  enable = true;
      #  useOSProber = true;
      #  timeoutStyle = "menu";
      #};
      #timeout = 300;
    };

    initrd = { 
      availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
      kernelModules = [ ];
    };

    # Make /tmp a tmpfs
    tmp = {
      useTmpfs = false;
      tmpfsSize = "30%";
      };
    
    # Appimage Support
    binfmt.registrations.appimage = {
      wrapInterpreterInShell = false;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
      magicOrExtension = ''\x7fELF....AI\x02'';
      };
    
    plymouth.enable = false;  

  };

  drivers.nvidia.enable = true;
  #vm.guest-services.enable = false;
  local.hardware-clock.enable = true;


  nix = {
    settings = {
      #warn-dirty = false;
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      substituters = [
        "https://nix-gaming.cachix.org" 
        "https://hyprland.cachix.org"
        ];
      trusted-public-keys = [
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 60d";
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
  #    allowUnfreePredicate = pkg: builtins.elem (builtins.parseDrvName pkg.name).name ["steam"];
  #    packageOverrides = pkgs: {
  #      
  #      #Make unstable packages available
  #      unstable = import (fetchTarball {
  #        url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  #        sha256 = "17pikpqk1icgy4anadd9yg3plwfrsmfwv1frwm78jg2rf84jcmq2";
  #      }) {config = { allowUnfree = true; };};
  #      
  #      #old_chrome = import (fetchTarball {
  #      #  url = "https://github.com/nixos/nixpkgs/archive/f02fa2f654c7bcc45f0e815c29d093da7f1245b4.tar.gz";
  #      #  sha256 = "";
  #      #}) {config = { allowUnfree = true; };};
  #
  #  };
    
    
    #overlays = [
    #  (self: super: {
    #    google-chrome = super.google-chrome.override {
    #      commandLineArgs =
    #        "--password-store=basic";
    #    };
    #  })
    #];

    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/7435c3ee-ec8c-4653-943d-f00a3f50e5a5";
    fsType = "ext4";
  };

  #fileSystems."/boot" = {
  #device = "/dev/disk/by-uuid/7435c3ee-ec8c-4653-943d-f00a3f50e5a5";
  #fsType = "ext4";
  #};

  #fileSystems."/home" = {
  #device = "/dev/disk/by-uuid/7435c3ee-ec8c-4653-943d-f00a3f50e5a5";
  #fsType = "ext4";
  #};

  fileSystems."/run/media/ajhyperbit/SATA SSD" = {
    device = "/dev/disk/by-uuid/c879995c-386a-42c2-bc3b-8d02a03c61de";
    fsType = "ext4";
    options = [ 
      # If you don't have this options attribute, it'll default to "defaults" 
      # boot options for fstab. Search up fstab mount options you can use
      "users" # Allows any user to mount and unmount
      "nofail" # Prevent system from failing if this drive doesn't mount
      "exec" # Permit execution of binaries and other executable files
    
    ];
  };

  fileSystems."/run/media/ajhyperbit/Transfer" = {
    device = "/dev/disk/by-uuid/F7F7-F2D7";
    fsType = "exfat";
    options = [ 
      # If you don't have this options attribute, it'll default to "defaults" 
      # boot options for fstab. Search up fstab mount options you can use
      "users" # Allows any user to mount and unmount
      "nofail" # Prevent system from failing if this drive doesn't mount
      "exec" # Permit execution of binaries and other executable files
      #TODO: add to links https://github.com/NixOS/nixpkgs/issues/55807 ?
      "uid=1000" 
      "gid=100" 
      "dmask=007" 
      "fmask=117"
    ];
  };

  lib.mkMerge = [{
    environment.systemPackages = 
    
    let
      winapps =
        (import (builtins.fetchTarball "https://github.com/winapps-org/winapps/archive/main.tar.gz"))
        .packages."x86_64-linux";
    in
    [
      winapps.winapps
      winapps.winapps-launcher # optional
    ];
    }];

  environment.systemPackages = (with pkgs; [

  #(catppuccin-sddm.override {
  #  flavor = "mocha";
  #  font  = "Noto Sans";
  #  fontSize = "9";
  #  #background = "${./wallpaper.png}";
  #  loginBackground = true;
  #  })

  neovim  
  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  wget
  google-chrome
  chromium
    # System Packages
    baobab
    btrfs-progs
    clang
    curl
    #cpufrequtils
    duf
    eza
    ffmpeg   
    glib #for gsettings to work
    gsettings-qt
    killall
    libappindicator
    openssl #required by Rainbow borders
    xdg-user-dirs
    xdg-utils
    fastfetch
    (mpv.override {scripts = [mpvScripts.mpris];}) # with tray
    #ranger



  #Games
  steam
    gamescope
  steamtinkerlaunch
  rare
  protonup-qt
    #For Need for Speed Most Wanted
    glibc
  discord
      (discord.override {
      # remove any overrides that you don't want
      withOpenASAR = true;
      withVencord = true;
      })
    vesktop #for sharing audio on discord, since normal discord has
  wine
  wine64
  wine-staging
  winetricks
  playonlinux
  protontricks
  bottles
  (lutris.override {
    extraPkgs = pkgs: [
      # List package dependencies here
      wineWowPackages.stable
      winetricks
    ];
    })
  gsmartcontrol

  #System tools
  gparted
  monitor
  putty
  htop
  remmina
  ethtool
  hwinfo
  wireshark
  ddclient
  #cinnamon.nemo-with-extensions
  vlc
  xdotool
  pciutils
  kdePackages.kate
  #libsForQt5.sddm-kcm
  #libsForQt5.kwin
  neofetch
  fastfetch
  ghfetch
  screenfetch
  xrdp
  xorg.xinit
  x11vnc
  nix-index
  fetchutils
  #Antivirus GUI
  #clamtk
  #Password things
  pass
  #keepassxc
  #Manage Files as admin
  kdePackages.kio-admin
  #Printing #TODO: revert once updated so not vulnerable to lots of 2024 CVEs at least one of which is a 9.9
  #cups-filters
  #cups-printers
  #canon-cups-ufr2
  #cups-bjnp
  
  #Vulkan
  vulkan-loader
  vulkan-validation-layers
  vulkan-tools

  #Windows VM or Filesystem compatiblity
  qemu
  exfatprogs
    #Related to Virtualisation in settings
    dive # look into docker image layers
    podman-tui # status of containers in the terminal
    #docker-compose # start group of containers for dev
    podman-compose # start group of containers for dev


  #Productivity / Video things
  (wrapOBS {
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-vkcapture
      obs-multi-rtmp
      obs-source-clone
      obs-source-record
      obs-source-switcher
      obs-websocket
      waveform
      obs-vaapi
      obs-teleport
      obs-scale-to-sound
      obs-nvfbc
      #obs-ndi
      obs-move-transition
      obs-command-source
      input-overlay
      #advanced-scene-switcher
      droidcam-obs
    ];
  })
  
  davinci-resolve-studio

  #Coding
  gitFull
    gittyup
    gh
  vscode-fhs
  #quickemu
  #quickgui
  direnv
  python3Full
	python312Packages.pip
	virtualenv
  docker
  nodejs_22
  obsidian
  #synergy

  #Twitch
  chatterino2

  #Misc
  spotify
  parsec-bin
  unrar
  zenith-nvidia
  clinfo
  gwe
  nvtopPackages.nvidia
  virtualglLib
  tailscale
  parsec-bin
  jq
  qdirstat
  service-wrapper
  autokey
  ntfs3g
  nvd
  p7zip
  rpi-imager
  xclicker
  #Calculators
  kdePackages.kcalc
  #qalculate-qt
  lastpass-cli
  dconf2nix
  coppwr
  pwvucontrol

  libsForQt5.kde-gtk-config
  libsForQt5.breeze-qt5
  libsForQt5.breeze-gtk
  libsForQt5.qt5ct
  libsForQt5.breeze-icons
  libsForQt5.oxygen

  #Makes other distros available to me
  #distrobox
  
  # Hyprland Stuff
    ags        
    btop
    brightnessctl # for brightness control
    cava
    #cliphist
    #eog
    eog
    gnome-system-monitor
    #file-roller
    gtk-engine-murrine #for gtk themes
    hypridle # requires unstable channel
    imagemagick 
    inxi
    libsForQt5.qtstyleplugin-kvantum #kvantum
    nwg-look # requires unstable channel
    nvtopPackages.full
    pamixer
    pavucontrol
    playerctl
    pyprland
    qt6ct
    qt6.qtwayland
    qt6Packages.qtstyleplugin-kvantum #kvantum
    swappy
    unzip
    wallust
    wlogout
    yad
    yt-dlp

(pkgs.hyprland.override { # or inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland
  #enableXWayland = true;  # whether to enable XWayland
  #legacyRenderer = false; # whether to use the legacy renderer (for old GPUs)
  withSystemd = true;     # whether to build with systemd support
})

  
  #Hyperland  #https://www.youtube.com/watch?v=61wGzIv12Ds
  #Terminals
  kitty
  #Alternatives
  #alacritty
  #wezterm

  #Screenshots
  hyprshot
    grim
    slurp
    wl-clipboard

  meson
  waybar
  (pkgs.waybar.overrideAttrs (oldAttrs: {
    mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
  })
  )
  #eww
  dunst
  #mako
  libnotify
  swaynotificationcenter
  networkmanagerapplet
  #Wallpaper Daemons
  #hyprpaper
  #swaybg
  #wpaperd
  #mpvpaper
  swww
  #App Launcher
  #most popular
  rofi-wayland
  #gtk rofi
  wofi
  #Wiki also suggests
  bemenu
  fuzzel
  tofi
  
  #Polkit agent
  polkit
  #libsForQt5.polkit-qt
  #kdePackages.polkit-qt-1
  #libsForQt5.polkit-kde-agent
  #kdePackages.polkit-kde-agent-1
  polkit_gnome

  hyprcursor # requires unstable channel
  
  #check if running via xwayland or wayland
  xorg.xwininfo

  #Bluetooth
  #blueman
  overskride

  #Compilers
  #gcc
  #clang
  #nvc

  #glib
  #cmake
  #pkg-config

  #Libraries
  libsecret
  egl-wayland

  #gobject-introspection
  #dbus-glib
  #gtk4
  #gtk3
  #gjs
  #libpulseaudio
  #pam
  #typescript
  #ninja
  #axel
  #tinyxml-2

  ]) ++ [
	  python-packages
  ];

  hardware = {
    pulseaudio ={
    
    enable = false;
    package = pkgs.pulseaudioFull;

    };
    
    bluetooth = {
	    enable = true;
	    powerOnBoot = true;
	    settings = {
		    General = {
		      Enable = "Source,Sink,Media,Socket";
		      #Experimental = true;
		    };
      };
    };
#    opengl = {
#      enable = true;
#      driSupport32Bit = lib.mkDefault true;
#      
#      #---------------------------------------------------------------------
#      # Install additional packages that improve graphics performance and compatibility.
#      #---------------------------------------------------------------------
#      extraPackages = with pkgs; [
#        intel-media-driver # LIBVA_DRIVER_NAME=iHD
#        libvdpau
#        libvdpau-va-gl
#        vdpauinfo
#        nvidia-vaapi-driver
#        vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
#        vaapiVdpau
#        #vulkan-validation-layers
#  	    libva
# 		    libva-utils		
#      ];
#      graphics = {
#        enable = true;
#        enable32Bit = lib.mkDefault true;
#        #---------------------------------------------------------------------
#        # Install additional packages that improve graphics performance and compatibility.
#        #---------------------------------------------------------------------
#        extraPackages = with pkgs; [
#          intel-media-driver # LIBVA_DRIVER_NAME=iHD
#          libvdpau-va-gl
#          nvidia-vaapi-driver
#          vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
#          vaapiVdpau
#          vulkan-validation-layers
#        ];
#      
#    };

#    nvidia = {
#
#    # Modesetting is required.
#    modesetting.enable = true;
#
#    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
#    # Enable this if you have graphical corruption issues or application crashes after waking
#    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
#    # of just the bare essentials.
#    powerManagement.enable = false;
#
#    # Fine-grained power management. Turns off GPU when not in use.
#    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
#    powerManagement.finegrained = false;
#
#    # Use the NVidia open source kernel module (not to be confused with the
#    # independent third-party "nouveau" open source driver).
#    # Support is limited to the Turing and later architectures. Full list of 
#    # supported GPUs is at: 
#    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
#    # Only available from driver 515.43.04+
#    # Currently alpha-quality/buggy, so false is currently the recommended setting.
#    open = false;
#
#    # Enable the Nvidia settings menu,
#	# accessible via `nvidia-settings`.
#    nvidiaSettings = true;
#
#    # Optionally, you may need to select the appropriate driver version for your specific GPU.
#    package = config.boot.kernelPackages.nvidiaPackages.stable;
#  };
#
#  nvidia-container-toolkit.enable = true;
  };

  #NOTE: From Chris Titus' configuration.nix
  #    kernelModules = ["tcp_bbr"];
  #    kernel.sysctl = {
  #      "net.ipv4.tcp_congestion_control" = "bbr";
  #      "net.core.default_qdisc" = "fq";
  #      "net.core.wmem_max" = 1073741824;
  #      "net.core.rmem_max" = 1073741824;
  #      "net.ipv4.tcp_rmem" = "4096 87380 1073741824";
  #      "net.ipv4.tcp_wmem" = "4096 87380 1073741824";
  #    };
  #  };

  #  networking = {
  #    hostName = "nixos-studio";
  #    networkmanager.enable = true;
  #    enableIPv6 = false;
  #    firewall.enable = false;
  #  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    enableIPv6 = false;
    interfaces.enp6s0.wakeOnLan.enable = true;
    timeServers = options.networking.timeServers.default ++ [ "pool.ntp.org" ];
    firewall.enable = true;
    #Allow VNC and Synergy through firewall
    firewall.allowedTCPPorts = [ 5900 24800 ];
    #firewall.allowedUDPPorts = [ ... ];
  };

  # Set your time zone.
  time.timeZone = "America/Chicago";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };
  };

  #console = {
  #  packages = [pkgs.terminus_font];
  #  font = "${pkgs.terminus_font}/share/consolefonts/ter-i22b.psf.gz";
  #  useXkbConfig = true;
  #};

  services = {
    # Enable the OpenSSH daemon.
    openssh = {
      enable = true;
      #Allow X11vnc through SSH. (probably unneccesary with tailscale)
      settings.X11Forwarding = true;
    };

    flatpak.enable = true;

    dbus.enable = true;

    #Different Compositor that might be conflicting
    #picom.enable = true;

    #gnome.gnome-keyring.enable = true;

    tailscale.enable = true;

    envfs.enable = true;

    #DDNS config
    ddclient = {
      enable = true;
      configFile = "/etc/ddclient/ddclient.conf";
    };

    #clamav = {
    #  scanner.enable = true;
    #  updater.enable = true;
    #};

    fstrim = {
      enable = true;
      interval = "weekly";
    };

    displayManager = {
      sddm = {
        enable = true;
        #wayland.enable = true;
        #theme = "catppuccin-mocha";
      };
      autoLogin = {
        enable = false;
        user = "ajhyperbit";
      };
    };
      
    xserver = {
      enable = true;
      #windowManager.dwm.enable = true;
      videoDrivers = ["nvidia"];
      #Keyboard
      xkb = {
        layout = "us";
        variant = "";
      };


      desktopManager.plasma5.enable = true; 

      displayManager = {
        #x11VNC / VNC
        sessionCommands = ''
          ${pkgs.x11vnc}/bin/x11vnc -bg -reopen -forever -rfbauth $HOME/.vnc/passwd -display :0 &
        '';
      };
    };
        #These might have been renamed as well
        # Enable the GNOME Desktop Environment.
        #displayManager.gdm.enable = true;
        #desktopManager.gnome.enable = true;

        #services.desktopManager.plasma6.enable = true;
        #Plasma wayland stuff
        #services.displayManager.sddm.wayland.enable = true;
        #services.displayManager.defaultSession = "plasmawayland"; #uncomment to enable plasma wayland, recomment to enable plasma x11

        # Enable Pantheon Desktop
        #services.xserver.desktopManager.pantheon.enable = true;

        # Enable MATE Desktop
        #services.xserver.desktopManager.mate.enable = true;

        # Enable Cinnamon Desktop
        #services.xserver.desktopManager.cinnamon.enable = true;
        #services.cinnamon.apps.enable = true;

        #environment.systemPackages = [
        #  pkgs.cinnamon.cinnamon-common
        #];

        #From Chris Titus' configuration.nix
        #lightdm.enable = true;
        #setupCommands = ''
        #  ${pkgs.xorg.xrandr}/bin/xrandr --output DP-1 --off --output DP-2 --off --output DP-3 --off --output HDMI-1 --mode 1920x1080 --pos 0x0 --rotate normal
        #'';
  
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber = {
            configPackages = [
              (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/11-bluetooth-policy.conf" ''
                wireplumber.settings = {
                  bluetooth.autoswitch-to-headset-profile = false
                }'')
                ];
            extraConfig = {
              "log-level-debug" = {
                "context.properties" = {
                  # Output Debug log messages as opposed to only the default level (Notice)
                  "log.level" = "D";
                };
              };
              "wh-1000xm3-ldac-hq" = {
                "monitor.bluez.rules" = [
                  {
                    matches = [
                      {
                        # Match any bluetooth device with ids equal to that of a WH-1000XM3
                        "device.name" = "~bluez_card.*";
                        "device.product.id" = "0x0cd3";
                        "device.vendor.id" = "usb:054c";
                      }
                    ];
                    actions = {
                      update-props = {
                        # Set quality to high quality instead of the default of auto
                        "bluez5.a2dp.ldac.quality" = "hq";
                      };
                    };
                  }
                ];
              };
            };
          };
      };

    #Auto CPU Freq
    #auto-cpufreq.enable = true;
    # Fwupd # Firmware updater
    fwupd = {
      enable = true;
    };
        #Printing 
        #TODO: look into gutenprint and brlaser and/or pkgs.brgenml1lpr and pkgs.brgenml1cupswrapper for brother printers)
        #TODO: add this link into a future compiled file https://askubuntu.com/questions/1090410/16-04-how-do-i-install-canon-pixma-mg3620-driver
        #TODO: break up printing into it's own printing.nix?
        #TODO: revert once updated so not vulnerable to lots of 2024 CVEs at least one of which is a 9.9
        #printing.enable = true;
        #avahi = {
        #  enable = true;
        #  nssmdns4 = true;
        #  openFirewall = true;
        #};

    #Hyprland
    hypridle.enable = true;
        
    #greetd = {
    #  enable = true;
    #  vt = 3;
    #  settings = {
    #    default_session = {
    #      user = username;
    #      command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland"; # start Hyprland with a TUI login manager
    #    };
    #  };
    #};

    smartd = {
      enable = false;
      autodetect = true;
    };
    
	  gvfs.enable = true;
	  tumbler.enable = true;

    udev.enable = true;

    libinput.enable = true;

    rpcbind.enable = false;
    nfs.server.enable = false;

	  upower.enable = true;

  };
  

  #NOTE: From Chris Titus' configuration.nix
  #nixpkgs.overlays = [
  #  (final: prev: {
  #    dwm = prev.dwm.overrideAttrs (old: {src = /home/${user}/CTT-Nix/system/dwm-titus;}); #FIX ME: Update with path to your dwm folder
  #  })
  #];

  #NOTE: From Chris Titus' configuration.nix
  #users.users.titus = {
  #  isNormalUser = true;
  #  description = "Titus";
  #  extraGroups = [
  #    "flatpak"
  #    "disk"
  #    "qemu"
  #    "kvm"
  #    "libvirtd"
  #    "sshd"
  #    "networkmanager"
  #    "wheel"
  #    "audio"
  #    "video"
  #    "libvirtd"
  #    "root"
  #  ];
  #};

  users.users.ajhyperbit = {
    isNormalUser = true;
    description = "AJHyperBit";
    extraGroups = [ 
      "flatpak"
      "disk"
      "qemu"
      "kvm"
      "libvirtd"
      "sshd"
      "networkmanager"
      "wheel"
      "audio"
      "video"
      "libvirtd"
      "root" 
    ];
  };

  programs ={
    
    #Hyprland
	  hyprland = {
      enable = true;
		  package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland; #hyprland-git
		  portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland; # xdphls
  	  xwayland.enable = true;
      };
	  waybar.enable = true;
	  hyprlock.enable = true;
	  firefox.enable = true;
	  git.enable = true;

    thunar.enable = true;
	  thunar.plugins = with pkgs.xfce; [
		  exo
		  mousepad
		  thunar-archive-plugin
		  thunar-volman
		  tumbler
  	  ];

    #KDE window borders fix
    dconf.enable = true;
    #fuse.userAllowOther = true;
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      extraCompatPackages = with pkgs; [
      proton-ge-bin
      steamtinkerlaunch
      ];
    };

    #Virtualization (Windows VM) #TODO: move to it's own module (unsure if laptop will ever do some kind of Windows VM stuff, might just RDP/Parsec/VNC into it.)
    virt-manager.enable = true;

    #seahorse.enable = true;
    #Workaround for error: "The option `programs.ssh.askPassword' has conflicting definition values:"
    ssh = {
    #KDE
    #askPassword = pkgs.lib.mkForce "${pkgs.ksshaskpass.out}/bin/ksshaskpass";
    #Gnome / Seahorse
    #askPassword = lib.mkForce "${pkgs.gnome.seahorse}/libexec/seahorse/ssh-askpass";
    };


    #TODO: (Research) Something coding related (VS code talks about it)
    direnv.enable = true;
  
    nix-ld = {
      enable = true;
      libraries = pkgs.steam-run.fhsenv.args.multiPkgs pkgs;
    };
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
    GBM_BACKEND = "nvidia-drm";
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    #QT_QPA_PLATFORM = "wayland;xcb";
    #QT_QPA_PLATFORMTHEME= "qt5ct";
    #GDK_BACKEND = "wayland,x11,*";
    #NVD_BACKEND = "direct";
  };
  };

  fonts = {
    #Fonts support 
    enableDefaultPackages = true;

    packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      fira-code
      jetbrains-mono
      terminus_font
      font-awesome
      source-han-sans
      source-han-sans-japanese
      source-han-serif-japanese
      nerdfonts
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = ["Meslo LG M Regular Nerd Font Complete Mono"];
        serif = ["Noto Serif" "Source Han Serif"];
        sansSerif = ["Noto Sans" "Source Han Sans"];
      };
     };
    };

  #Virtualisation
  virtualisation = {
    libvirtd.enable = true;
    # Enable common container config files in /etc/containers
    containers = {
      enable = true;
      };
    #Podman https://nixos.wiki/wiki/Podman
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
      };
  };

  #XDG Portals
  xdg = {
    #autostart.enable = true;
    portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = with pkgs; [ 
        #xdg-desktop-portal
        xdg-desktop-portal-kde
        xdg-desktop-portal-gtk
      ];
      xdgOpenUsePortal = true;
    configPackages = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal
    ];

    config = {
    #  common = {
    #    default = [
    #      "kde"
    #      ];
    #  };
      #"org.freedesktop.impl.portal.FileChooser"= [
      #  "kde"
      #    ];
    };
    };
  };

  #TODO: I dunno (research later?) (still don't know, keeping it anyway)
  qt = {
    enable = true;
    style = "breeze";
    platformTheme = "kde";
  };

  security = {
    pam = {
      services = {
        sddm.kwallet.enable = true;
        #login.kwallet.enable = true;
        kde.kwallet.enable = true;
        hyprland.kwallet.enable = true;
        #sddm.enableGnomeKeyring = true;
        #login.enableGnomeKeyring = true;
        #kde.enableGnomeKeyring = true;
        #hyprland.enableGnomeKeyring = true;
        swaylock = {
          text = ''
            auth include login
          '';
        };
      };
    };
    rtkit.enable = true;

    polkit = {
    enable = true;
    extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (
          subject.isInGroup("users")
            && (
              action.id == "org.freedesktop.login1.reboot" ||
              action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
              action.id == "org.freedesktop.login1.power-off" ||
              action.id == "org.freedesktop.login1.power-off-multiple-sessions"
            )
          )
        {
          return polkit.Result.YES;
        }
      })
    '';
    };
  };
  
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  # Microcode
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  #Sleep settings
  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';

  documentation.nixos.enable = false;
  
  #home-manager.useGlobalPkgs = true;
  #home-manager.useUserPackages = true;
  #home-manager.users.ajhyperbit = { imports = [ ./config/home.nix ];};
  #home-manager.extraSpecialArgs = {inherit inputs self username;};
  #home-manager.backupFileExtension = "hm-bak";


  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
    };
    services.flatpak-repo = {
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };
  };

  # zram
  zramSwap = {
	  enable = true;
	  priority = 100;
	  memoryPercent = 30;
	  swapDevices = 1;
    algorithm = "zstd";
    };

  #powerManagement = {
  #	enable = true;
	#  cpuFreqGovernor = "schedutil";
  #};

  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;
  };



  #systemd = {
  #  user.services.polkit = {
  #    description = "polkit";
  #    wantedBy = [ "graphical-session.target" ];
  #    wants = [ "graphical-session.target" ];
  #    after = [ "graphical-session.target" ];
  #    serviceConfig = {
  #        Type = "simple";
  #        ExecStart = "${pkgs.polkit}/libexec/polkit-gnome-authentication-agent-1";
  #        Restart = "on-failure";
  #        RestartSec = 1;
  #        TimeoutStopSec = 10;
  #      };
  #  };
  #};

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}