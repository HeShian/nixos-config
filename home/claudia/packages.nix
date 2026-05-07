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
#   - 远程桌面 & 文件传输（Remmina/Localsend）
#   - 音乐 & 游戏
#   - 工具（Bilibili TUI/MPV/yt-dlp/virt-manager）
# ==============================================================================

{
  home.packages = with pkgs; [
    kitty
    fuzzel
    swaylock
    brightnessctl  # 屏幕亮度控制
    eza           # 彩色 ls（带图标）
    bat           # 彩色 cat（语法高亮）
    btop          # 系统监控
    fastfetch     # 系统信息显示
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

    # --- 远程桌面 & 文件传输 ---
    remmina                    # 远程桌面客户端（RDP/VNC/SSH）
    localsend                  # 跨平台文件传输（AirDrop 替代）

    # --- 音乐 ---
    go-musicfox                # Musicfox —— 终端网易云音乐

    # --- 游戏 ---
    lutris                     # 游戏平台（WINE 管理器）
    heroic                     # Heroic Games Launcher（Epic/GOG/Amazon）

    # --- 工具 ---
    bilibili-tui              # Bilibili TUI 终端客户端
    mpv                       # 视频播放器（bilibili-tui 依赖）
    yt-dlp                    # 视频流提取（bilibili-tui 依赖）
    virt-manager              # 虚拟机管理器（KVM 前端）
    xwayland-satellite         # XWayland 兼容层（niri 需要）
    mpvScripts.bdanmaku       # Bilibili 弹幕 mpv 插件
    biliass                   # Bilibili 弹幕转 ASS 字幕
  ];
}
