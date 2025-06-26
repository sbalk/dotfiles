# /etc/nixos/configuration.nix
# Final, merged configuration for the new system.

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
  networking.firewall.allowedTCPPorts = [ 10300 ];

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
  services.displayManager.gdm.enable = false;
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.gnome.enable = true;
  services.desktopManager.cosmic.enable = true;
  # Workaround for current COSMIC bugs
  systemd.user.extraConfig = ''
    DefaultEnvironment="PATH=/run/current-system/sw/bin"
  '';
  services.geoclue2.enable = true;  # https://github.com/NixOS/nixpkgs/issues/259641#issuecomment-2910335440

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
  };
  services.wyoming.faster-whisper.servers.echo = {
    enable = true;
    model = "large-v3";
    language = "en";
    device = "cuda";
    uri = "tcp://0.0.0.0:10300";
  };

  # --- Other Services ---
  programs.steam.enable = true;
  services.blueman.enable = true;
  services.fwupd.enable = true;
  services.syncthing.enable = true;
  services.tailscale.enable = true;
  services.printing.enable = true;

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
    yq-go
    xclip

    # Development Toolchains
    cargo
    cmake
    cudatoolkit
    go
    meson
    nodejs_20
    openjdk
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
