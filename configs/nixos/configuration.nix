# /etc/nixos/configuration.nix
# NixOS -- basnijholt/dotfiles

{ config, pkgs, ... }:

let
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{
  imports = [
    ./kinto.nix
    ./hardware-configuration.nix
    (import "${home-manager}/nixos")
  ];


  # ===================================
  # Boot Configuration
  # ===================================
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    useOSProber = true;
    device = "nodev";
    memtest86.enable = true;
    theme = pkgs.sleek-grub-theme.override {
      withStyle = "orange";
      withBanner = "Welcome Bas!";
    };
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # ===================================
  # Hardware Configuration
  # ===================================
  # --- NVIDIA Graphics ---
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  hardware.nvidia-container-toolkit.enable = true;
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  # --- Swap ---
  swapDevices = [{
    device = "/swapfile";
    size = 16 * 1024; # 16GB
  }];

  # ===================================
  # System Configuration
  # ===================================
  # --- Core Settings ---
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # --- Hostname & Networking ---
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [
    10200  # Wyoming Piper
    10300  # Wyoming Faster Whisper - English
    10301  # Wyoming Faster Whisper - Dutch
    10400  # Wyoming OpenWakeword
    8880   # Kokoro TTS
  ];

  # --- Nix Package Manager Settings ---
  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://cuda-maintainers.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };

  # --- Nixpkgs Configuration ---
  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
  };

  # --- Fonts ---
  fonts.packages = with pkgs; [
    fira-code
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.jetbrains-mono
  ];

  # ===================================
  # User Configuration
  # ===================================
  users.users.basnijholt = {
    isNormalUser = true;
    description = "Bas Nijholt";
    extraGroups = [ "networkmanager" "wheel" "docker" "libvirtd" ];
    shell = pkgs.zsh;
  };

  # ===================================
  # Desktop Environment
  # ===================================
  # --- X11 & Display Managers ---
  services.xserver.enable = true;
  services.xserver.xkb = { layout = "us"; variant = ""; };
  programs.dconf.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # --- Hyprland ---
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = "gtk";
      };
      hyprland = {
        default = [ "hyprland" "gtk" ];
      };
    };
  };

  # ===================================
  # System Programs & Services
  # ===================================
  # --- Shell & Terminal ---
  programs.zsh.enable = true;
  programs.direnv.enable = true;

  # --- SSH ---
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      UseDns = true;
      X11Forwarding = true;
    };
  };

  # --- Security & Authentication ---
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };
  programs._1password.enable = true;
  programs._1password-gui.enable = true;
  programs._1password-gui.polkitPolicyOwners = ["basnijholt"];

  # --- Virtualization ---
  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # --- AI & Machine Learning ---
  services.ollama = {
    enable = true;
    acceleration = "cuda";
    host = "0.0.0.0";
    openFirewall = true;
    environmentVariables = {
      OLLAMA_KEEP_ALIVE = "1h";
    };
  };
  services.wyoming.faster-whisper = {
    servers.english = {
      enable = true;
      model = "large-v3";
      language = "en";
      device = "cuda";
      uri = "tcp://0.0.0.0:10300";
    };
    servers.dutch = {
      enable = false;
      model = "large-v3";
      language = "nl";
      device = "cuda";
      uri = "tcp://0.0.0.0:10301";
    };
  };
  services.wyoming.piper.servers.yoda = {
    enable = true;
    voice = "en-us-ryan-high";
    uri = "tcp://0.0.0.0:10200";
  };
  services.wyoming.openwakeword = {
    enable = true;
    preloadModels = [
      "alexa"
      "hey_jarvis"
      "ok_nabu"
    ];
    uri = "tcp://0.0.0.0:10400";
  };
  services.qdrant = {
    enable = true;
    settings = {
      storage = {
        storage_path = "/var/lib/qdrant/storage";
        snapshots_path = "/var/lib/qdrant/snapshots";
      };
      service = {
        host = "0.0.0.0";
        http_port = 6333;
      };
      telemetry_disabled = true;
    };
  };

  # --- Other Services ---
  programs.steam.enable = true;
  services.blueman.enable = true;
  services.fwupd.enable = true;
  services.syncthing.enable = true;
  services.tailscale.enable = true;
  services.printing.enable = true;

  # Sunshine notes: Had to change the `https://discourse.nixos.org/t/give-user-cap-sys-admin-p-capabillity/62611/2`
  # in Sunshine Steam App `sudo -u myuser setsid steam steam://open/bigpicture` as Detached Command
  # then in Steam Settings: Interface -> "Enable GPU accelerated ..." but disable "hardware video decoding"
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };


  # --- System Compatibility ---
  programs.nix-ld.enable = true;  # Run non-nix executables (e.g., micromamba)

  # ===================================
  # System Packages
  # ===================================
  environment.systemPackages = with pkgs; [
    # GUI Applications
    _1password-gui
    _1password-cli
    brave
    calibre
    code-cursor
    cryptomator
    docker
    dropbox
    filebot
    firefox
    handbrake
    inkscape
    moonlight-qt
    mullvad-vpn
    obs-studio
    obsidian
    qbittorrent
    signal-desktop
    slack
    spotify
    telegram-desktop
    tor-browser-bundle-bin
    vlc
    vscode

    # CLI Power Tools & Utilities
    asciinema
    atuin
    azure-cli
    bat
    btop
    coreutils
    duf
    eza
    fzf
    gh
    git
    git-lfs
    git-secret
    gnugrep
    gnupg
    gnused
    htop
    iperf3
    jq
    just
    keyd
    lazygit
    lm_sensors
    micro
    neovim
    nixfmt
    nmap
    nvtopPackages.full
    ollama
    parallel
    pinentry-gnome3
    psmisc # For killall
    pwgen
    rclone
    ripgrep
    starship
    tealdeer
    terraform
    tmux
    tree
    typst
    wget
    xclip
    yq-go
    zellij

    # Development Toolchains
    cargo
    cmake
    cudatoolkit
    gcc
    go
    meson
    nodejs_20
    openjdk
    pkg-config
    portaudio
    (python3.withPackages (ps: [ ps.pipx ]))
    rust-analyzer
    winetricks

    # Terminals & Linux-native Alternatives
    alacritty
    baobab
    flameshot
    ghostty
    kitty
    opensnitch

    # Hyprland Essentials
    polkit_gnome
    waybar          # Status bar (most popular by far)
    wofi            # Application launcher (simpler than rofi)
    mako            # Notification daemon (Wayland-native)
    swww            # Wallpaper daemon (smooth transitions)
    wl-clipboard    # Clipboard manager (copy/paste support)
    cliphist        # Clipboard history
    hyprlock        # Screen locker
    hyprpicker      # Color picker
    hyprshot        # Screenshot tool (Hyprland-specific)
  ];

  # ===================================
  # Home Manager Configuration
  # ===================================
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.basnijholt = { pkgs, config, ... }: {
      home.stateVersion = "25.05";

      # --- Mechabar Dependencies ---
      home.packages = with pkgs; [
        bluetui
        bluez
        brightnessctl
        pipewire
        wireplumber
        rofi-wayland
      ];
    };
  };

  # The system state version is critical and should match the installed NixOS release.
  system.stateVersion = "25.05";
}
