{ config, pkgs, ... }:

# ==============================================================================
# niri —— Scrollable-tiling Wayland 合成器配置
#
#   本文件部署 niri 的配置文件（~/.config/niri/config.kdl，KDL 格式）。
#   使用 xdg.configFile 将生成好的配置内容写入用户目录。
#
#   配置结构：
#   - 输入设备（键盘、触摸板、鼠标）
#   - 显示器输出（缩放）
#   - 窗口布局（间距、列宽预设、聚焦边框、阴影）
#   - 环境变量（语言、输入法、Qt 主题、光标）
#   - 快捷键绑定（Vim 风格窗口管理、应用启动、媒体键）
#   - 窗口规则（圆角、浮动、几何形状）
#   - 动画（Spring 弹性动画）
#
#   配置格式说明：niri 使用 KDL（一种声明式配置语言），
#   不同于 Nix 的 {} 块结构，KDL 使用 {} 但不需要逗号分隔。
#   include 指令用于引入 DMS 自动生成的配置片段。
#
#   参考配置：
#   - 官方 default-config.kdl
#   - shorin 风格配置：https://github.com/SHORiN-KiWATA/shorin-dms-niri
#   - DMS 文档：https://github.com/nicemachine/DankMaterialShell
# ==============================================================================

let
  # gsettings-desktop-schemas 的编译后 schema 目录
  # NixOS 将 schema 放在非标准路径 share/gsettings-schemas/... 下，
  # 需要设置 GSETTINGS_SCHEMA_DIR 让 GTK4/libadwaita 应用能找到。
  gsettingsSchemaDir =
    "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";

  niriConfig = pkgs.writeText "niri-config.kdl" ''
    // niri 配置文件 —— KDL 格式
    // 文档: https://niri-wm.github.io/niri/Configuration:-Introduction

    // ==========================================================================
    // 外部引用
    //   DMS 会自动生成 cursor.kdl（光标主题和大小）和 colors.kdl（动态配色），
    //   这两个文件由 DMS 在运行时按需更新，不要手动编辑。
    // ==========================================================================
    include "dms/cursor.kdl"
    include "dms/colors.kdl"

    // ==========================================================================
    // 输入设备
    // ==========================================================================
    input {
        keyboard {
            xkb {
                // 键盘布局：默认从 org.freedesktop.locale1 自动获取
            }
        }

        touchpad {
            tap                                    // 启用轻触点击
            natural-scroll                         // 自然滚动（类似 macOS）
        }

        mouse {
            // 鼠标设置：默认，无特殊配置
        }
    }

    // ==========================================================================
    // 显示器输出
    //   缩放比例：1.25x（适合 1080p 屏幕获得更好的 UI 尺寸）
    //   如果显示器名称不是 eDP-1，运行 `niri msg outputs` 查看实际名称
    // ==========================================================================
    output "eDP-1" {
        scale 1.25
    }

    // ==========================================================================
    // 窗口布局（shorin 风格）
    // ==========================================================================
    layout {
        gaps 12                                    // 窗口间距 12px

        center-focused-column "never"              // 从不自动居中聚焦列

        // 预设列宽（通过 Mod+R 循环切换）
        preset-column-widths {
            proportion 0.33333                     // 1/3 宽度
            proportion 0.5                         // 1/2 宽度（默认）
            proportion 0.66667                     // 2/3 宽度
        }

        default-column-width { proportion 0.5; }   // 新窗口默认 50% 宽度

        // 聚焦窗口边框
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

        // 屏幕预留空间（用于状态栏/ dock）
        struts {
            // left 64
            // right 64
            // top 64
            // bottom 64
        }
    }

    // ==========================================================================
    // 环境变量
    //   这些变量在 niri 启动时设置，影响所有子进程（应用）。
    // ==========================================================================
    environment {
        LANGUAGE "zh_CN.UTF-8"
        LANG "zh_CN.UTF-8"
        LC_CTYPE "en_US.UTF-8"                    // 使用 en_US 解决 Rime 输入法漏字问题
        XMODIFIERS "@im=fcitx"
        GTK_IM_MODULE "fcitx"
        QT_IM_MODULE "fcitx"
        MOZ_ENABLE_WAYLAND "1"
        QT_QPA_PLATFORMTHEME "gtk3"               // Qt5 使用 GTK3 主题
        QT_QPA_PLATFORMTHEME_QT6 "gtk3"           // Qt6 使用 GTK3 主题
        XCURSOR_THEME "Adwaita"                    // Wayland 原生光标主题
        XCURSOR_SIZE "24"
        EXO_TERMINAL_EMULATOR "kitty"              // Thunar 等使用 kitty 作为终端
        GST_PLUGIN_SYSTEM_PATH_1_0 "${pkgs.gst_all_1.gst-plugins-bad}/lib/gstreamer-1.0"
        EDITOR "nvim"
        GSETTINGS_SCHEMA_DIR "${gsettingsSchemaDir}"
    }

    // ==========================================================================
    // 截图保存路径
    // ==========================================================================
    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

    // 启动时跳过快捷键教程
    hotkey-overlay {
        skip-at-startup
    }

    // 隐藏窗口标题栏（要求 CSD 客户端使用 SSD 装饰）
    prefer-no-csd

    // ==========================================================================
    // 自动启动
    // ==========================================================================
    spawn-at-startup "fcitx5"                                      // 启动输入法
    spawn-sh-at-startup "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=niri GSETTINGS_SCHEMA_DIR"

    // ==========================================================================
    // 全局背景模糊设置
    //   自 niri 26.04 引入，影响所有启用了 background-effect 的窗口。
    //   passes：采样次数（值越大越模糊，GPU 开销越大）
    //   offset：采样间距（增大可提升平滑度，无额外 GPU 开销）
    //   noise：噪点强度（减少色带伪影）
    //   saturation：色彩饱和度（1.0=原始, >1=增艳）
    // ==========================================================================
    blur {
        passes 3
        offset 3.0
        noise 0.02
        saturation 1.5
    }

    // ==========================================================================
    // 动画（shorin 风格 — Spring 弹性动画）
    //   使用阻尼弹簧（damped spring）模型，参数：
    //   damping-ratio：阻尼比（0=无阻尼振荡, 1=临界阻尼）
    //   stiffness：弹簧刚度（值越大动画越快）
    //   epsilon：精度阈值
    // ==========================================================================
    animations {
        slowdown 0.98                                              // 轻微慢放

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

    // ==========================================================================
    // 窗口规则
    //   根据应用 ID（app-id）或标题（title）匹配合适的窗口行为。
    // ==========================================================================

    // WezTerm —— 保持默认列宽
    window-rule {
        match app-id=r#"^org\.wezfurlong\.wezterm$"#
        default-column-width {}
    }

    // GNOME 原生应用 —— 去除背景边框，设置圆角
    window-rule {
        match app-id=r#"^org\.gnome\."#
        draw-border-with-background false
        geometry-corner-radius 12
        clip-to-geometry true
    }

    // 设置类应用 —— 中等宽度，不要浮动
    window-rule {
        match app-id=r#"^gnome-control-center$"#
        match app-id=r#"^pavucontrol$"#
        match app-id=r#"^nm-connection-editor$"#
        default-column-width { proportion 0.5; }
        open-floating false
    }

    // 工具类应用 —— 浮动窗口
    window-rule {
        match app-id=r#"^gnome-calculator$"#
        match app-id=r#"^blueman-manager$"#
        match app-id=r#"^xdg-desktop-portal$"#
        open-floating true
    }

    // GNOME 工具套件 —— 浮动
    window-rule {
        match app-id=r#"^org\.gnome\.Calculator$"#
        match app-id=r#"^org\.gnome\.Characters$"#
        match app-id=r#"^org\.gnome\.Weather$"#
        open-floating true
    }

    // Firefox 画中画 —— 浮动
    window-rule {
        match app-id=r#"firefox$"# title="^Picture-in-Picture$"
        open-floating true
    }

    // 终端应用 —— 避免背景边框（为了透明背景效果）
    window-rule {
        match app-id="Alacritty"
        match app-id="kitty"
        match app-id="org.wezfurlong.wezterm"
        draw-border-with-background false
    }

    // DMS Shell —— 浮动（状态栏和控件层）
    window-rule {
        match app-id=r#"org.quickshell$"#
        open-floating true
    }

    // 全局窗口模糊 —— 为半透明窗口开启背景模糊
    //   xray 默认启用：只模糊壁纸背景，性能开销小
    //   如需要真模糊（模糊所有遮挡内容），可设 xray false
    //   （注意：xray false 为实验性功能，性能开销更大）
    window-rule {
        background-effect {
            blur true
        }
    }

    // 全局圆角 —— 所有窗口统一应用
    window-rule {
        geometry-corner-radius 12
        clip-to-geometry true
    }

    // ==========================================================================
    // 快捷键绑定
    //   Mod = Super（Windows 键）
    //   遵循 Vim 风格导航：H/J/K/L 代替方向键
    // ==========================================================================
    binds {
        // ---- 帮助 ----
        Mod+Shift+Slash { show-hotkey-overlay; }

        // ---- 启动程序 ----
        Mod+T hotkey-overlay-title="打开终端: kitty" { spawn "kitty"; }
        Mod+Z hotkey-overlay-title="运行应用: fuzzel" { spawn "fuzzel"; }
        Mod+B hotkey-overlay-title="打开浏览器: firefox" { spawn "firefox"; }
        Mod+E hotkey-overlay-title="打开文件管理器: Thunar" { spawn "thunar"; }
        Super+Alt+L hotkey-overlay-title="锁定屏幕: swaylock" { spawn "swaylock"; }
        Super+Alt+S allow-when-locked=true hotkey-overlay-title=null { spawn-sh "pkill orca || exec orca"; }

        // ---- 音量控制（允许锁屏时使用） ----
        XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"; }
        XF86AudioMute        allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
        XF86AudioMicMute     allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }

        // ---- 媒体键 ----
        XF86AudioPlay        allow-when-locked=true { spawn-sh "playerctl play-pause"; }
        XF86AudioStop        allow-when-locked=true { spawn-sh "playerctl stop"; }
        XF86AudioPrev        allow-when-locked=true { spawn-sh "playerctl previous"; }
        XF86AudioNext        allow-when-locked=true { spawn-sh "playerctl next"; }

        // ---- 亮度控制（允许锁屏时使用） ----
        XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "+10%"; }
        XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "10%-"; }

        // ---- 窗口管理 ----
        Mod+O repeat=false { toggle-overview; }                    // 概览模式
        Mod+G repeat=false { toggle-overview; }
        Mod+Q repeat=false { close-window; }                       // 关闭窗口

        // 焦点移动（Vim 风格：H=左 J=下 K=上 L=右）
        Mod+Left  { focus-column-left; }
        Mod+Down  { focus-window-down; }
        Mod+Up    { focus-window-up; }
        Mod+Right { focus-column-right; }
        Mod+H     { focus-column-left; }
        Mod+J     { focus-window-down; }
        Mod+K     { focus-window-up; }
        Mod+L     { focus-column-right; }

        // 窗口移动（Ctrl + 方向键）
        Mod+Ctrl+Left  { move-column-left; }
        Mod+Ctrl+Down  { move-window-down; }
        Mod+Ctrl+Up    { move-window-up; }
        Mod+Ctrl+Right { move-column-right; }
        Mod+Ctrl+H     { move-column-left; }
        Mod+Ctrl+J     { move-window-down; }
        Mod+Ctrl+K     { move-window-up; }
        Mod+Ctrl+L     { move-column-right; }

        // 首尾列跳转
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

        // 窗口跨显示器移动
        Mod+Shift+Ctrl+Left  { move-column-to-monitor-left; }
        Mod+Shift+Ctrl+Down  { move-column-to-monitor-down; }
        Mod+Shift+Ctrl+Up    { move-column-to-monitor-up; }
        Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }
        Mod+Shift+Ctrl+H     { move-column-to-monitor-left; }
        Mod+Shift+Ctrl+J     { move-column-to-monitor-down; }
        Mod+Shift+Ctrl+K     { move-column-to-monitor-up; }
        Mod+Shift+Ctrl+L     { move-column-to-monitor-right; }

        // ---- 工作区切换（U=向下 I=向上，匹配 Vim Ctrl+U/Ctrl+I 的习惯） ----
        Mod+Page_Down      { focus-workspace-down; }
        Mod+Page_Up        { focus-workspace-up; }
        Mod+U              { focus-workspace-down; }
        Mod+I              { focus-workspace-up; }
        Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
        Mod+Ctrl+Page_Up   { move-column-to-workspace-up; }
        Mod+Ctrl+U         { move-column-to-workspace-down; }
        Mod+Ctrl+I         { move-column-to-workspace-up; }

        // 工作区移动
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

        // ---- 数字键工作区（1-9） ----
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
        Mod+BracketLeft  { consume-or-expel-window-left; }        // 窗口归入/移出左侧列
        Mod+BracketRight { consume-or-expel-window-right; }
        Mod+Comma  { consume-window-into-column; }               // 窗口归入当前列
        Mod+Period { expel-window-from-column; }                 // 窗口移出当前列

        // ---- 宽度/高度调节 ----
        Mod+R { switch-preset-column-width; }                    // 切换预设列宽（循环）
        Mod+Shift+R { switch-preset-column-width-back; }         // 反向切换
        Mod+Ctrl+Shift+R { switch-preset-window-height; }       // 切换预设窗口高度
        Mod+Ctrl+R { reset-window-height; }                     // 重置窗口高度

        Mod+F { maximize-column; }                               // 最大化列
        Mod+Shift+F { fullscreen-window; }                      // 全屏窗口
        Mod+M { maximize-window-to-edges; }                     // 窗口扩展到边缘
        Mod+Ctrl+F { expand-column-to-available-width; }        // 列扩展到可用宽度
        Mod+C { center-column; }                                 // 居中列
        Mod+Ctrl+C { center-visible-columns; }                  // 居中可见列

        // 微调宽度/高度（±10%）
        Mod+Minus { set-column-width "-10%"; }
        Mod+Equal { set-column-width "+10%"; }
        Mod+Shift+Minus { set-window-height "-10%"; }
        Mod+Shift+Equal { set-window-height "+10%"; }

        // ---- 浮动窗口 ----
        Mod+V       { toggle-window-floating; }                  // 切换窗口浮动
        Mod+Shift+V { switch-focus-between-floating-and-tiling; } // 切换焦点的浮动/平铺

        // ---- 标签模式 ----
        Mod+W { toggle-column-tabbed-display; }                  // 列标签显示

        // ---- 截图快捷键 ----
        Mod+Alt+A { screenshot; }                                // 区域截图
        Print { screenshot; }                                    // PrintScreen 键
        Shift+Print { screenshot-screen; }                       // 全屏截图
        Alt+Print { screenshot-window; }                         // 当前窗口截图
        Mod+Shift+S { spawn-sh "grim -g \"$(slurp)\" - | satty -f -"; }  // 截图并标注

        // ---- 剪贴板历史 ----
        Mod+Alt+V { spawn-sh "cliphist list | fuzzel --dmenu --prompt=\"📋 剪贴板> \" | cliphist decode | wl-copy"; }

        // ---- 特殊操作 ----
        Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }
        Mod+Shift+E { quit; }                                    // 退出 niri
        Ctrl+Alt+Delete { quit; }
        Mod+Shift+P { power-off-monitors; }                     // 关闭显示器
    }
  '';
in {
  # ============================================================================
  # 部署 niri 配置文件
  #   通过 xdg.configFile 将生成的 KDL 配置写入 ~/.config/niri/config.kdl
  #   force = true → 如果文件已存在则覆盖（Home Manager 管理此文件）
  #
  #   ⚠️ 注意：Home Manager 接管后，手动编辑 ~/.config/niri/config.kdl 会被覆盖！
  #   如需修改快捷键或窗口行为，请编辑本文件然后运行：
  #     home-manager switch --flake /etc/nixos#claudia
  # ============================================================================
  xdg.configFile."niri/config.kdl" = {
    source = niriConfig;
    force = true;
  };
}
