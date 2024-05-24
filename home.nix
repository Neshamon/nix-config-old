{ config, pkgs, wezterm-git, system, inputs, ... }:
let
  sdl2Path = "$(nix eval --raw nixpkgs#SDL2.outPath)/lib";
  sdl2imgPath = "$(nix eval --raw nixpkgs#SDL2_image.outPath)/lib";
  sdl2ttfPath = "$(nix eval --raw nixpkgs#SDL2_ttf.outPath)/lib";
  libffiPath = "$(nix eval --raw nixpkgs#libffi.outPath)/lib";
  libffiDevPath = "$(nix eval --raw nixpkgs#libffi.dev.outPath)/lib/pkgconfig";
  gccPath = "$(nix eval --raw nixpkgs#gcc.outPath)/lib";
  openGLPath = "$(nix eval --raw nixpkgs#libGL.outPath)/lib";
  pipewirePath = "$(nix eval --raw nixpkgs#pipewire.outPath)/lib";
  openSSLPath = "$(nix eval --raw nixpkgs#openssl.out)/lib";
in {
  home-manager.users.neshamon = {
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    home.username = "neshamon";
    home.homeDirectory = "/home/neshamon";

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    home.stateVersion = "22.11"; # Please read the comment before changing.

    # The home.packages option allows you to install Nix packages into your
    # environment.
    home.packages = with pkgs; [
      # # Adds the 'hello' command to your environment. It prints a friendly
      # # "Hello, world!" when run.
      # pkgs.hello

      # # It is sometimes useful to fine-tune packages, for example, by applying
      # # overrides. You can do that directly here, just don't forget the
      # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
      # # fonts?
      # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

      # # You can also create simple shell scripts directly inside your
      # # configuration. For example, this adds a command 'my-hello' to your
      # # environment:
      # (pkgs.writeShellScriptBin "my-hello" ''
      #   echo "Hello, ${config.home.username}!"
      # '')
      firefox
      signal-desktop
      base16-schemes
      element-desktop
      exercism
      neofetch
    ];

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    # plain files is through 'home.file'.
    home.file = {
      # # Building this configuration will create a copy of 'dotfiles/screenrc' in
      # # the Nix store. Activating the configuration will then make '~/.screenrc' a
      # # symlink to the Nix store copy.
      # ".screenrc".source = dotfiles/screenrc;

      # # You can also set the file content immediately.
      # ".gradle/gradle.properties".text = ''
      #   org.gradle.console=verbose
      #   org.gradle.daemon.idletimeout=3600000
      # '';
    };

    # You can also manage environment variables but you will have to manually
    # source
    #
    #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
    #
    # or
    #
    #  /etc/profiles/per-user/neshamon/etc/profile.d/hm-session-vars.sh
    #
    # if you don't want to manage your shell through Home Manager.
    home.sessionVariables = {
      EDITOR = "emacs";
      TERMINAL = "wezterm";
      LD_LIBRARY_PATH =
        "${openGLPath}:${sdl2Path}:${sdl2imgPath}:${sdl2ttfPath}:${pipewirePath}:${gccPath}:${libffiPath}:${openSSLPath}:$LD_LIBRARY_PATH";
      PKG_CONFIG_PATH = "${libffiDevPath}";
    };

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;

    programs.git = {
      enable = true;
      userName = "neshamon";
      userEmail = "jmmatthews@proton.me";

    };

    programs.zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      syntaxHighlighting = { enable = true; };
    };

    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      package = pkgs.starship;
    };

    gtk = { enable = true; };

    programs.emacs = {
      enable = true;
      package = pkgs.emacs29-pgtk;
    };

    programs.wezterm = {
      enable = true;
      package = pkgs.callPackage ./wezterm.nix { inherit inputs; };
      enableZshIntegration = true;
      extraConfig = ''
        local gpus = wezterm.gui.enumerate_gpus()
        return {
          webgpu_preferred_adapter = gpus[1],
          --webgpu_force_fallback_adapter = true;
          front_end = "OpenGL",
          hide_tab_bar_if_only_one_tab = true,
          enable_wayland = true,
        }
      '';
    };

    services.mako = {
      enable = true;
      package = pkgs.mako;
      borderRadius = 5;
      anchor = "top-center";
    };

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
      extraConfig = ''
        exec-once=zsh ~/.config/hypr/start.sh
      '';
      settings = {
        input = {
          kb_layout = "us";

          follow_mouse = 1;
        };

        general = {
          gaps_in = 5;
          gaps_out = 20;
          border_size = 2;
          layout = "dwindle";
        };

        decoration = {
          rounding = 10;
          drop_shadow = "yes";
          shadow_range = 4;
          shadow_render_power = 3;
          blur = {
            enabled = true;
            size = 3;
            passes = 1;
            new_optimizations = true;
          };
        };

        animations = {
          enabled = "yes";

          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

          animation = [
            "windows,1,7,myBezier"
            "windowsOut,1,7,default,popin 80%"
            "border,1,10,default"
            "borderangle,1,8,default"
            "fade,1,7,default"
            "workspaces,1,6,default"
          ];
        };

        dwindle = {
          pseudotile = "yes";
          preserve_split = "yes";
        };

        master = { new_is_master = "yes"; };

        monitor = "HDMI-A-1,1920x1080@240,0x0,1";

        bind = [
          "SUPER, Q, exec, wezterm"
          "SUPER, S, exec, fuzzel"
          "SUPER, C, killactive,"
          "SUPER, M, exit,"
          "SUPER, E, exec, emacs"
          "SUPER, V, togglefloating"
          "SUPER, R, exec, firefox"
          "SUPER, P, pseudo," # dwindle
          "SUPER, J, togglesplit," # dwindle

          # Move focus with mainMod + arrow keys
          "SUPER, left, movefocus, 1"
          "SUPER, right, movefocus, r"
          "SUPER, up, movefocus, u"
          "SUPER, down, movefocus, d"

          # Switch workspaces with mainMod + [0-9]
          "SUPER, 1, workspace, 1"
          "SUPER, 2, workspace, 2"
          "SUPER, 3, workspace, 3"
          "SUPER, 4, workspace, 4"
          "SUPER, 5, workspace, 5"
          "SUPER, 6, workspace, 6"
          "SUPER, 7, workspace, 7"
          "SUPER, 8, workspace, 8"
          "SUPER, 9, workspace, 9"
          "SUPER, 0, workspace, 10"

          # Move active window to a workspace with mainMod + SHIFT + [0-9]
          "SUPERSHIFT, 1, movetoworkspace, 1"
          "SUPERSHIFT, 2, movetoworkspace, 2"
          "SUPERSHIFT, 3, movetoworkspace, 3"
          "SUPERSHIFT, 4, movetoworkspace, 4"
          "SUPERSHIFT, 5, movetoworkspace, 5"
          "SUPERSHIFT, 6, movetoworkspace, 6"
          "SUPERSHIFT, 7, movetoworkspace, 7"
          "SUPERSHIFT, 8, movetoworkspace, 8"
          "SUPERSHIFT, 9, movetoworkspace, 9"
          "SUPERSHIFT, 0, movetoworkspace, 10"

          # Scroll through existing workspaces with mainMod + scroll
          "SUPER, mouse_down, workspace, e+1"
          "SUPER, mouse_up, workspace, e-1"

          # Move/resize windows with mainMod + LMB/RMB and dragging
          "SUPER, mouse:272, movewindow"
          "SUPER, mouse:273, resizeactive"
        ];
      };
    };

    programs = {
      nnn = {
        enable = true;
        package = pkgs.nnn;
      };

      bat = { enable = true; };

      fuzzel = {
        enable = true;
        package = pkgs.fuzzel;
        settings = {
          main = {
            line-height = 50;
            width = 140;
            lines = 10;
          };

          border = {
            width = 2;
            radius = 10;
          };
        };
      };
    };

    # Targets must be inside home-manager
    stylix = {
      targets = {
        wezterm = { enable = true; };

        emacs = { enable = true; };

        hyprland = { enable = true; };

        mako = { enable = true; };

        bat = { enable = true; };

        fuzzel = { enable = true; };
      };
    };
  };

  stylix = {
    #stylix.base16Scheme = theme;
    image = ./inside.png;
    polarity = "dark";

    cursor = {
      package = pkgs.graphite-cursors;
      name = "graphite-dark-nord";
    };

    fonts = {

      monospace = {
        package = pkgs.iosevka;
        name = "Iosevka";
      };

      serif = config.stylix.fonts.monospace;
      sansSerif = config.stylix.fonts.monospace;
    };

    opacity = {
      applications = 0.95;
      terminal = 0.9;
      desktop = 0.95;
      popups = 0.7;
    };
  };
}
