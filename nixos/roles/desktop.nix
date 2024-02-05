{ pkgs, ... }:

let secrets = import ../secrets.nix;
in {
  nixpkgs.overlays = [
    (import "${
        builtins.fetchTarball
        "https://github.com/nix-community/nixpkgs-wayland/archive/master.tar.gz"
      }/overlay.nix")
  ];
  boot.loader.timeout = 0;
  security.sudo = {
    wheelNeedsPassword = false;
    extraConfig = ''
      Defaults env_keep += "TMUX"
    '';
  };
  users.users.jaksi = {
    extraGroups = [ "wheel" ];
    hashedPassword = secrets.hashedUserPassword;
    isNormalUser = true;
  };
  sound.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };
  programs = {
    sway.enable = true;
    firefox.enable = true;
  };
  environment = {
    persistence."/nix/persist/system".directories =
      [ "/var/lib/alsa" "/home/jaksi/.mozilla" ];
    systemPackages = with pkgs; [ alacritty playerctl ];
    etc."sway/config".text = ''
      include /etc/sway/config.d/*
      set $mod Mod4
      set $left h
      set $down j
      set $up k
      set $right l
      bindsym $mod+Return exec alacritty
      bindsym $mod+Backspace exec firefox
      bindsym $mod+Shift+q kill
      floating_modifier $mod normal
      bindsym $mod+Shift+c reload
      bindsym $mod+Shift+e exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -B 'Yes, exit sway' 'swaymsg exit'
      bindsym $mod+$left focus left
      bindsym $mod+$down focus down
      bindsym $mod+$up focus up
      bindsym $mod+$right focus right
      bindsym $mod+Left focus left
      bindsym $mod+Down focus down
      bindsym $mod+Up focus up
      bindsym $mod+Right focus right
      bindsym $mod+Shift+$left move left
      bindsym $mod+Shift+$down move down
      bindsym $mod+Shift+$up move up
      bindsym $mod+Shift+$right move right
      bindsym $mod+Shift+Left move left
      bindsym $mod+Shift+Down move down
      bindsym $mod+Shift+Up move up
      bindsym $mod+Shift+Right move right
      bindsym $mod+1 workspace number 1
      bindsym $mod+2 workspace number 2
      bindsym $mod+3 workspace number 3
      bindsym $mod+4 workspace number 4
      bindsym $mod+5 workspace number 5
      bindsym $mod+6 workspace number 6
      bindsym $mod+7 workspace number 7
      bindsym $mod+8 workspace number 8
      bindsym $mod+9 workspace number 9
      bindsym $mod+0 workspace number 10
      bindsym $mod+Shift+1 move container to workspace number 1
      bindsym $mod+Shift+2 move container to workspace number 2
      bindsym $mod+Shift+3 move container to workspace number 3
      bindsym $mod+Shift+4 move container to workspace number 4
      bindsym $mod+Shift+5 move container to workspace number 5
      bindsym $mod+Shift+6 move container to workspace number 6
      bindsym $mod+Shift+7 move container to workspace number 7
      bindsym $mod+Shift+8 move container to workspace number 8
      bindsym $mod+Shift+9 move container to workspace number 9
      bindsym $mod+Shift+0 move container to workspace number 10
      bindsym $mod+b splith
      bindsym $mod+v splitv
      bindsym $mod+s layout stacking
      bindsym $mod+w layout tabbed
      bindsym $mod+e layout toggle split
      bindsym $mod+f fullscreen
      bindsym $mod+Shift+space floating toggle
      bindsym $mod+space focus mode_toggle
      bindsym $mod+a focus parent
      mode "resize" {
          bindsym $left resize shrink width 10px
          bindsym $down resize grow height 10px
          bindsym $up resize shrink height 10px
          bindsym $right resize grow width 10px
          bindsym Left resize shrink width 10px
          bindsym Down resize grow height 10px
          bindsym Up resize shrink height 10px
          bindsym Right resize grow width 10px
          bindsym Return mode "default"
          bindsym Escape mode "default"
      }
      bindsym $mod+r mode "resize"
      bar {
          position top
          status_command while date +'%Y-%m-%d %X'; do sleep 1; done
          colors {
              statusline #ffffff
              background #323232
              inactive_workspace #32323200 #32323200 #5c5c5c
          }
      }
      bindsym XF86AudioRaiseVolume exec wpctl set-volume 54 5%+
      bindsym XF86AudioLowerVolume exec wpctl set-volume 54 5%-
      bindsym XF86AudioMute exec wpctl set-mute 54 toggle
      bindsym XF86AudioPlay exec playerctl play-pause
      bindsym XF86AudioNext exec playerctl next
      bindsym XF86AudioPrev exec playerctl previous
    '';
  };
}