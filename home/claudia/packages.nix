{ config, pkgs, ... }:

# ==============================================================================
# 用户级软件包
#
#   本文件管理用户 claudia 的用户级软件包（仅当前用户可用，无需 sudo）。
#   系统级软件包（全局可用）请见 hosts/westwood/packages.nix。
#
#   包分组：
#   - 基础工具
#   - 通讯社交（微信/QQ/Telegram/Discord）
#   - 下载工具（gopeed/qbittorrent）
#   - 文档 & 阅读（Okular/Readest/NovelWriter）
#   - 远程桌面 & 文件传输（Remmina/Localsend）
#   - 音乐（Strawberry/Musicfox）
#   - 游戏（Lutris/Heroic）
#   - Wine 管理（Bottles/ProtonPlus）
#   - 工具 & 虚拟化（Siyuan/KDE Connect/Digikam/Virt-Manager）
# ==============================================================================

{
  home.packages = with pkgs; [
    kitty
    ghostty       # 现代、原生、功能丰富的终端模拟器（Mod+Enter 启动）
    fuzzel
    swaylock
    brightnessctl  # 屏幕亮度控制
    eza           # 彩色 ls（带图标）
    bat           # 彩色 cat（语法高亮）
    btop          # 系统监控
    fastfetch     # 系统信息显示
    yazi                # 终端文件管理器（异步 I/O，Vim 风格操作）
    satty         # 截图标注编辑
    grim          # Wayland 截图
    slurp         # 区域选择
    cliphist      # 剪贴板历史
    wl-clipboard   # wl-copy/wl-paste
    xfce4-exo      # exo-open（Thunar 右键打开终端依赖）

    # --- 通讯社交 ---
    wechat                     # 微信
    qq                         # QQ
    wemeet                     # 腾讯会议
    telegram-desktop           # Telegram
    discord                    # Discord

    # --- 下载工具 ---
    gopeed                     # 现代下载管理器
    qbittorrent                # BitTorrent 客户端

    # --- 文档 & 阅读 ---
    kdePackages.okular          # KDE 文档查看器（PDF/EPUB/CBZ/DjVu）
    readest                     # 现代电子书阅读器（EPUB/MOBI/PDF）
    novelwriter                 # 小说写作编辑器（纯文本，专注长文创作）

    # --- 远程桌面 & 文件传输 ---
    remmina                    # 远程桌面客户端（RDP/VNC/SSH）
    localsend                  # 跨平台文件传输（AirDrop 替代）

    # --- 音乐 ---
    go-musicfox                # Musicfox —— 终端网易云音乐
    strawberry                # 音乐播放器与音乐收藏管理器

    # --- 游戏 ---
    lutris                     # 游戏平台（WINE 管理器）
    heroic                     # Heroic Games Launcher（Epic/GOG/Amazon）

    # --- Wine 管理 ---
    bottles                     # Wine 前缀管理器（图形界面）
    protonplus                  # Wine/Proton 兼容工具管理器

    # --- 工具 & 虚拟化 ---
    bilibili-tui              # Bilibili TUI 终端客户端
    mpv                       # 视频播放器（bilibili-tui 依赖）
    yt-dlp                    # 视频流提取（bilibili-tui 依赖）
    virt-manager              # 虚拟机管理器（KVM 前端）
    virt-viewer               # SPICE/VNC 客户端（virt-manager 虚拟机控制台）
    spice-gtk                 # SPICE GTK 客户端库（virt-viewer 依赖）
    xwayland-satellite         # XWayland 兼容层（niri 需要）
    mpvScripts.bdanmaku       # Bilibili 弹幕 mpv 插件
    biliass                   # Bilibili 弹幕转 ASS 字幕
    siyuan                     # 思源笔记 —— 隐私优先的个人知识管理系统
    kdePackages.kdeconnect-kde # KDE Connect —— 跨设备通信与文件传输
    digikam                    # 数码照片管理与编辑（KDE）
    gearlever                  # AppImage 管理器（一键集成到应用菜单）

  ];
}
