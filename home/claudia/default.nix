{ config, pkgs, inputs, lib, ... }:

# ==============================================================================
# Home Manager —— 用户：claudia
#   本文件是用户级配置的总入口，通过 imports 引入各程序子模块。
#   所有配置只影响当前用户，不会污染系统全局。
# ==============================================================================

{
  # 导入子模块 —— 按程序/功能拆分，方便维护
  imports = [
    ./shell.nix       # Shell 环境（bash / zsh / fish）
    ./git.nix         # Git 版本控制配置
    ./nvim.nix        # Nixvim（Neovim 编辑器配置）
    ./niri.nix        # niri Wayland 合成器配置
    ./xdg.nix         # XDG 基础配置（mimeapps、user-dirs、Xresources）
  ];

  # ============================================================================
  # 用户基本信息
  # ============================================================================
  home.username = "claudia";
  home.homeDirectory = "/home/claudia";

  # ============================================================================
  # Home Manager 版本（用于向后兼容判定，不要随意修改）
  # ============================================================================
  home.stateVersion = "25.11";

  # ============================================================================
  # 让 Home Manager 管理 Shell 的初始化文件（如 .bashrc、.zshrc）
  #   启用后，HM 会接管 ~/.bashrc 等文件的管理，手动修改将被覆盖
  # ============================================================================

  # ============================================================================
  # 用户级软件包（仅当前用户可用，不需要 sudo 安装）
  # ============================================================================
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

  # ============================================================================
  # MPV 配置（参考 emoeem/mpv 项目适配）
  # ============================================================================
  home.file.".config/mpv/mpv.conf" = {
    text = ''
      # ======================================================================
      # 视频输出
      # ======================================================================
      vo=gpu-next
      hwdec=nvdec-copy                    # NVIDIA NVDEC 硬解（copy 模式兼容 Wayland）
      hwdec-codecs=all                    # 全部编码格式尝试硬解
      gpu-context=wayland                 # Wayland 输出
      # gpu-api=vulkan                    # Vulkan 渲染（如支持可启用）

      # ======================================================================
      # 高质量缩放（GPU 内置算法）
      # ======================================================================
      profile=gpu-hq
      scale=ewa_lanczossharp
      cscale=bilinear
      dscale=catmull_rom
      scale-antiring=0.5
      dscale-antiring=0.5
      linear-upscaling=no
      sigmoid-upscaling=yes
      correct-downscaling=yes
      linear-downscaling=no

      # ======================================================================
      # 去色带
      # ======================================================================
      deband
      deband-iterations=1
      deband-threshold=48
      deband-range=16
      deband-grain=16

      # ======================================================================
      # HDR 色彩管理
      # ======================================================================
      icc-profile-auto
      icc-intent=0
      icc-force-contrast=1000
      icc-3dlut-size=128x128x128
      icc-cache-dir="~~/cache/icc_cache"

      # HDR 色调映射
      hdr-contrast-recovery=0.30
      hdr-compute-peak=auto
      tone-mapping=auto

      # ======================================================================
      # 视频同步
      # ======================================================================
      video-sync=display-resample

      # ======================================================================
      # 音频
      # ======================================================================
      ao=pipewire                         # PipeWire 音频后端
      audio-format=float                  # 32位浮点音频
      audio-channels=auto
      audio-file-auto=fuzzy
      volume-max=200
      alang=japanese,jpn,jap,ja,jp,english,eng,en
      replaygain=album

      # ======================================================================
      # OSD
      # ======================================================================
      osd-font="Noto Sans CJK SC;Noto Color Emoji"
      osd-font-size=24
      osd-color="#FFFFFF"
      osd-duration=2000
      osd-on-seek=msg-bar
      osd-playing-msg=''${filename}

      # ======================================================================
      # 字幕
      # ======================================================================
      sub-font="Noto Sans CJK SC;Noto Color Emoji"
      sub-font-size=50
      sub-bold=yes
      sub-color="#FFFFFF"
      sub-outline-size=0.5
      sub-outline-color="#000000"
      sub-shadow-offset=0.5
      sub-codepage=gb18030
      sub-auto=fuzzy
      sub-file-paths=sub;subs;subtitles;字幕
      slang=chs,sc,zh-Hans,zh-CN,cht,tc,zh-Hant,zh-HK,zh-TW,chi,zho,zh

      # ======================================================================
      # yt-dlp（Bilibili 等网络视频）
      # ======================================================================
      ytdl=yes
      ytdl-format=bestvideo[height<=?2160][vcodec!=?vp9.2]+bestaudio/best

      # ======================================================================
      # 截图
      # ======================================================================
      screenshot-format=webp
      screenshot-webp-quality=85
      screenshot-template="~~/files/screen/%{media-title}-%P-%n"

      # ======================================================================
      # 常规
      # ======================================================================
      save-position-on-quit=yes
      hr-seek=yes
      keep-open=yes
      idle=yes
      ontop                              # 窗口置顶
      save-watch-history=yes
      input-ipc-server=/tmp/mpvsocket
      msg-level=all=info,auto_profiles=warn

      # ======================================================================
      # Bilibili 弹幕（bdanmaku）
      # ======================================================================
      script-opts-append=biliass_executable=biliass
      script-opts-append=curl_executable=curl
    '';
  };

  # Bilibili 弹幕插件脚本 -> ~/.config/mpv/scripts/bdanmaku.lua
  home.file.".config/mpv/scripts/bdanmaku.lua".source =
    "${pkgs.mpvScripts.bdanmaku}/share/mpv/scripts/bdanmaku.lua";

  # ============================================================================
  # exo-open helpers.rc（Thunar 右键"在终端中打开"依赖此配置）
  # ============================================================================
  home.file.".config/xfce4/helpers.rc".text = ''
    TerminalEmulator=kitty
    TerminalEmulatorDismissed=true
  '';
  # ============================================================================
  # Thunar 默认终端设置为 kitty
  #   在每次 activation 时确保 xfconf 属性正确
  # ============================================================================
  home.activation.setThunarTerminal = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Thunar 默认终端
    ${pkgs.xfconf}/bin/xfconf-query -c thunar -p /default-terminal-emulator -s kitty 2>/dev/null || \
    ${pkgs.xfconf}/bin/xfconf-query -c thunar -p /default-terminal-emulator -n -t string -s kitty
    # exo-open 终端模拟器
    ${pkgs.xfconf}/bin/xfconf-query -c xfce4-appfinder -p /terminal-emulator/emulator -s kitty 2>/dev/null || \
    ${pkgs.xfconf}/bin/xfconf-query -c xfce4-appfinder -p /terminal-emulator/emulator -n -t string -s kitty
  '';
}
