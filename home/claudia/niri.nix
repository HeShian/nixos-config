{ config, pkgs, ... }:

# ==============================================================================
# niri —— Scrollable-tiling Wayland 合成器配置
#   使用 xdg.configFile 部署 ~/.config/niri/config.kdl
#   基于 niri 官方 default-config.kdl 修改
# ==============================================================================

let
  niriConfig = pkgs.writeText "niri-config.kdl" ''
    // niri 配置 —— KDL 格式
    // 文档: https://niri-wm.github.io/niri/Configuration:-Introduction

    // DMS 自动生成的配置（光标、颜色等）
    include "dms/cursor.kdl"
    include "dms/colors.kdl"

    // ============================================================================
    // 输入设备
    // ============================================================================
    input {
        keyboard {
            xkb {
                // 默认从 org.freedesktop.locale1 获取键盘布局
            }
        }

        touchpad {
            tap
            natural-scroll
        }

        mouse {
            // off
            // natural-scroll
        }
    }

    // ============================================================================
    // 输出（显示器）配置
    //   缩放 1.25x
    //   如果显示器不是 eDP-1，可运行 `niri msg outputs` 查看实际名称
    // ============================================================================
    output "eDP-1" {
        scale 1.25
    }

    // ============================================================================
    // 窗口布局（shorin 风格）
    // ============================================================================
    layout {
        // 窗口间距
        gaps 12

        center-focused-column "never"

        // 预设窗口宽度
        preset-column-widths {
            proportion 0.33333
            proportion 0.5
            proportion 0.66667
        }

        default-column-width { proportion 0.5; }

        // 聚焦边框
        focus-ring {
            width 3
        }

        border {
            width 1
        }

        // 窗口阴影
        shadow {
            on
            softness 20
            spread 2
            offset x=-4 y=-4
            color "rgba(0, 0, 0, 0.7)"
        }

        struts {
            // left 64
            // right 64
            // top 64
            // bottom 64
        }
    }


    // ============================================================================
    // 环境变量
    // ============================================================================
    environment {
        LANGUAGE "zh_CN.UTF-8"
        LANG "zh_CN.UTF-8"
        LC_CTYPE "en_US.UTF-8"                  // 解决输入法漏字
        XMODIFIERS "@im=fcitx"
        QT_QPA_PLATFORMTHEME "gtk3"
        QT_QPA_PLATFORMTHEME_QT6 "gtk3"
        XCURSOR_THEME "Adwaita"
        XCURSOR_SIZE "24"
        EXO_TERMINAL_EMULATOR "kitty"
        GST_PLUGIN_SYSTEM_PATH_1_0 "${pkgs.gst_all_1.gst-plugins-bad}/lib/gstreamer-1.0"
        EDITOR "nvim"
    }

    // ============================================================================
    // 截图保存路径
    // ============================================================================
    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

    // 启动时跳过快捷键教程
    hotkey-overlay {
        skip-at-startup
    }

    // 隐藏窗口标题栏（要求 CSD 程序使用 SSD）
    prefer-no-csd

    // ============================================================================
    // 自动启动
    // ============================================================================
    spawn-at-startup "fcitx5"
    spawn-sh-at-startup "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=niri"

    // ============================================================================
    // 动画（shorin 风格 — Spring 弹性动画）
    // ============================================================================
    animations {
        slowdown 0.98

        workspace-switch {
            spring damping-ratio=0.82 stiffness=400 epsilon=0.0001
        }

        horizontal-view-movement {
            spring damping-ratio=0.84 stiffness=400 epsilon=0.0001
        }

        window-open {
            spring damping-ratio=1.0 stiffness=1000 epsilon=0.0001
        }

        window-close {
            spring damping-ratio=0.8 stiffness=400 epsilon=0.0001
        }

        window-movement {
            spring damping-ratio=1.0 stiffness=800 epsilon=0.0001
        }

        window-resize {
            spring damping-ratio=0.9 stiffness=500 epsilon=0.0001
        }

        screenshot-ui-open {
            duration-ms 300
            curve "ease-out-quad"
        }

        overview-open-close {
            spring damping-ratio=1.0 stiffness=900 epsilon=0.0001
        }
    }

    // ============================================================================
    // 窗口规则
    // ============================================================================
    window-rule {
        match app-id=r#"^org\.wezfurlong\.wezterm$"#
        default-column-width {}
    }
    window-rule {
        match app-id=r#"^org\.gnome\."#
        draw-border-with-background false
        geometry-corner-radius 12
        clip-to-geometry true
    }
    window-rule {
        match app-id=r#"^gnome-control-center$"#
        match app-id=r#"^pavucontrol$"#
        match app-id=r#"^nm-connection-editor$"#
        default-column-width { proportion 0.5; }
        open-floating false
    }
    window-rule {
        match app-id=r#"^gnome-calculator$"#
        match app-id=r#"^blueman-manager$"#
        match app-id=r#"^xdg-desktop-portal$"#
        open-floating true
    }
    window-rule {
        match app-id=r#"^org\.gnome\.Calculator$"#
        match app-id=r#"^org\.gnome\.Characters$"#
        match app-id=r#"^org\.gnome\.Weather$"#
        open-floating true
    }
    window-rule {
        match app-id=r#"firefox$"# title="^Picture-in-Picture$"
        open-floating true
    }
    // 终端避免背景边框
    window-rule {
        match app-id="Alacritty"
        match app-id="kitty"
        match app-id="org.wezfurlong.wezterm"
        draw-border-with-background false
    }
    // DMS 窗口浮动
    window-rule {
        match app-id=r#"org.quickshell$"#
        open-floating true
    }
    // 全局窗口圆角
    window-rule {
        geometry-corner-radius 12
        clip-to-geometry true
    }

    // ============================================================================
    // 快捷键绑定
    // ============================================================================
    binds {
        // ---- 帮助 ----
        Mod+Shift+Slash { show-hotkey-overlay; }

        // ---- 启动程序 ----
        Mod+T hotkey-overlay-title="Open a Terminal: kitty" { spawn "kitty"; }
        Mod+Z hotkey-overlay-title="Run an Application: fuzzel" { spawn "fuzzel"; }
        Mod+B hotkey-overlay-title="Open Browser: firefox" { spawn "firefox"; }
        Mod+E hotkey-overlay-title="Open File Manager: Thunar" { spawn "thunar"; }
        Super+Alt+L hotkey-overlay-title="Lock the Screen: swaylock" { spawn "swaylock"; }
        Super+Alt+S allow-when-locked=true hotkey-overlay-title=null { spawn-sh "pkill orca || exec orca"; }

        // ---- 音量键 ----
        XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"; }
        XF86AudioMute        allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
        XF86AudioMicMute     allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }

        // ---- 媒体键 ----
        XF86AudioPlay        allow-when-locked=true { spawn-sh "playerctl play-pause"; }
        XF86AudioStop        allow-when-locked=true { spawn-sh "playerctl stop"; }
        XF86AudioPrev        allow-when-locked=true { spawn-sh "playerctl previous"; }
        XF86AudioNext        allow-when-locked=true { spawn-sh "playerctl next"; }

        // ---- 亮度键 ----
        XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "+10%"; }
        XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "10%-"; }

        // ---- 窗口管理 ----
        Mod+O repeat=false { toggle-overview; }
        Mod+G repeat=false { toggle-overview; }
        Mod+Q repeat=false { close-window; }

        // 焦点移动（Vim 风格）
        Mod+Left  { focus-column-left; }
        Mod+Down  { focus-window-down; }
        Mod+Up    { focus-window-up; }
        Mod+Right { focus-column-right; }
        Mod+H     { focus-column-left; }
        Mod+J     { focus-window-down; }
        Mod+K     { focus-window-up; }
        Mod+L     { focus-column-right; }

        // 窗口移动
        Mod+Ctrl+Left  { move-column-left; }
        Mod+Ctrl+Down  { move-window-down; }
        Mod+Ctrl+Up    { move-window-up; }
        Mod+Ctrl+Right { move-column-right; }
        Mod+Ctrl+H     { move-column-left; }
        Mod+Ctrl+J     { move-window-down; }
        Mod+Ctrl+K     { move-window-up; }
        Mod+Ctrl+L     { move-column-right; }

        Mod+Home { focus-column-first; }
        Mod+End  { focus-column-last; }
        Mod+Ctrl+Home { move-column-to-first; }
        Mod+Ctrl+End  { move-column-to-last; }

        // 显示器切换
        Mod+Shift+Left  { focus-monitor-left; }
        Mod+Shift+Down  { focus-monitor-down; }
        Mod+Shift+Up    { focus-monitor-up; }
        Mod+Shift+Right { focus-monitor-right; }
        Mod+Shift+H     { focus-monitor-left; }
        Mod+Shift+J     { focus-monitor-down; }
        Mod+Shift+K     { focus-monitor-up; }
        Mod+Shift+L     { focus-monitor-right; }

        Mod+Shift+Ctrl+Left  { move-column-to-monitor-left; }
        Mod+Shift+Ctrl+Down  { move-column-to-monitor-down; }
        Mod+Shift+Ctrl+Up    { move-column-to-monitor-up; }
        Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }
        Mod+Shift+Ctrl+H     { move-column-to-monitor-left; }
        Mod+Shift+Ctrl+J     { move-column-to-monitor-down; }
        Mod+Shift+Ctrl+K     { move-column-to-monitor-up; }
        Mod+Shift+Ctrl+L     { move-column-to-monitor-right; }

        // ---- 工作区 ----
        Mod+Page_Down      { focus-workspace-down; }
        Mod+Page_Up        { focus-workspace-up; }
        Mod+U              { focus-workspace-down; }
        Mod+I              { focus-workspace-up; }
        Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
        Mod+Ctrl+Page_Up   { move-column-to-workspace-up; }
        Mod+Ctrl+U         { move-column-to-workspace-down; }
        Mod+Ctrl+I         { move-column-to-workspace-up; }

        Mod+Shift+Page_Down { move-workspace-down; }
        Mod+Shift+Page_Up   { move-workspace-up; }
        Mod+Shift+U         { move-workspace-down; }
        Mod+Shift+I         { move-workspace-up; }

        // ---- 鼠标滚轮绑定 ----
        Mod+WheelScrollDown      cooldown-ms=150 { focus-column-right; }
        Mod+WheelScrollUp        cooldown-ms=150 { focus-column-left; }
        Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-right; }
        Mod+Ctrl+WheelScrollUp   cooldown-ms=150 { move-column-left; }

        Mod+Shift+WheelScrollDown      cooldown-ms=150 { focus-workspace-down; }
        Mod+Shift+WheelScrollUp        cooldown-ms=150 { focus-workspace-up; }
        Mod+Ctrl+Shift+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
        Mod+Ctrl+Shift+WheelScrollUp   cooldown-ms=150 { move-column-to-workspace-up; }

        Mod+WheelScrollRight      { focus-column-right; }
        Mod+WheelScrollLeft       { focus-column-left; }
        Mod+Ctrl+WheelScrollRight { move-column-right; }
        Mod+Ctrl+WheelScrollLeft  { move-column-left; }

        // ---- 数字工作区 ----
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }
        Mod+Ctrl+1 { move-column-to-workspace 1; }
        Mod+Ctrl+2 { move-column-to-workspace 2; }
        Mod+Ctrl+3 { move-column-to-workspace 3; }
        Mod+Ctrl+4 { move-column-to-workspace 4; }
        Mod+Ctrl+5 { move-column-to-workspace 5; }
        Mod+Ctrl+6 { move-column-to-workspace 6; }
        Mod+Ctrl+7 { move-column-to-workspace 7; }
        Mod+Ctrl+8 { move-column-to-workspace 8; }
        Mod+Ctrl+9 { move-column-to-workspace 9; }

        // ---- 列操作 ----
        Mod+BracketLeft  { consume-or-expel-window-left; }
        Mod+BracketRight { consume-or-expel-window-right; }
        Mod+Comma  { consume-window-into-column; }
        Mod+Period { expel-window-from-column; }

        // ---- 宽度/高度 ----
        Mod+R { switch-preset-column-width; }
        Mod+Shift+R { switch-preset-column-width-back; }
        Mod+Ctrl+Shift+R { switch-preset-window-height; }
        Mod+Ctrl+R { reset-window-height; }

        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }
        Mod+M { maximize-window-to-edges; }
        Mod+Ctrl+F { expand-column-to-available-width; }
        Mod+C { center-column; }
        Mod+Ctrl+C { center-visible-columns; }

        Mod+Minus { set-column-width "-10%"; }
        Mod+Equal { set-column-width "+10%"; }
        Mod+Shift+Minus { set-window-height "-10%"; }
        Mod+Shift+Equal { set-window-height "+10%"; }

        // ---- 浮动窗口 ----
        Mod+V       { toggle-window-floating; }
        Mod+Shift+V { switch-focus-between-floating-and-tiling; }

        // ---- 标签模式 ----
        Mod+W { toggle-column-tabbed-display; }

        // ---- 截图快捷键 ----
        Mod+Alt+A { screenshot; }
        Print { screenshot; }
        Shift+Print { screenshot-screen; }
        Alt+Print { screenshot-window; }
        Mod+Shift+S { spawn-sh "grim -g \"$(slurp)\" - | satty -f -"; }
        // ---- 剪贴板 ----
        Mod+Alt+V { spawn-sh "cliphist list | fuzzel --dmenu --prompt=\"📋 Clipboard> \" | cliphist decode | wl-copy"; }
        // ---- 特殊 ----
        Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }
        Mod+Shift+E { quit; }
        Ctrl+Alt+Delete { quit; }
        Mod+Shift+P { power-off-monitors; }
    }
  '';
in {
  # ============================================================================
  # niri 配置文件
  #   部署到 ~/.config/niri/config.kdl
  # ============================================================================
  xdg.configFile."niri/config.kdl" = {
    source = niriConfig;
    force = true;
  };
}
