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
  # ============================================================================
  # ============================================================================
  # Fcitx5 输入法主题 —— DMS 动态配色适配
  #
  #   DMS（DankMaterialShell）会根据壁纸生成动态主题色，但 fcitx5 的候选词窗口
  #   使用独立于 GTK/Qt 的 classicui 渲染，默认不会跟随 DMS 主题色。
  #
  #   本配置通过 DMS 的用户 matugen 模板系统（runUserMatugenTemplates 已启用），
  #   在 DMS 切换壁纸/主题时自动生成 fcitx5 的 theme.conf，使输入法候选框
  #   在所有应用中（terminal、Firefox、Electron 等）都使用一致的 DMS 配色。
  #
  #   工作原理：
  #     1. fcitx5.toml 告诉 DMS 模板引擎处理 fcitx5-theme.conf
  #     2. fcitx5-theme.conf 使用 matugen 颜色变量（{{colors.*.hex}}）定义主题
  #     3. DMS 渲染后将 theme.conf 输出到 DATA_DIR/fcitx5/themes/dms/
  #     4. classicui.conf 让 fcitx5 使用 "dms" 主题
  # ============================================================================

  # DMS 用户 matugen 模板配置 —— 定义 fcitx5 主题的输出路径
  home.file.".config/dms/templates/fcitx5.toml" = {
    text = 
''
      [templates.dmsfcitx5]
      input_path = 'CONFIG_DIR/dms/templates/fcitx5-theme.conf'
      output_path = 'DATA_DIR/fcitx5/themes/dms/theme.conf'
''
    ;
    force = true;
  };

  # DMS matugen 模板 —— fcitx5 候选词窗口主题
  home.file.".config/dms/templates/fcitx5-theme.conf" = {
    text = 
''
      [Metadata]
      Name=DMS Dynamic
      Version=1
      Author=DankMaterialShell
      Description=Dynamic DMS theme generated with Matugen
      ScaleWithDPI=True

      [InputPanel]
      NormalColor={{colors.on_surface.default.hex}}
      HighlightCandidateColor={{colors.on_primary.default.hex}}
      HighlightColor={{colors.primary.default.hex}}
      HighlightBackgroundColor={{colors.primary.default.hex}}
      PageButtonAlignment=Last Candidate

      [InputPanel/TextMargin]
      Left=5
      Right=5
      Top=5
      Bottom=5

      [InputPanel/ContentMargin]
      Left=2
      Right=2
      Top=2
      Bottom=2

      [InputPanel/Background]
      Color={{colors.surface_container_low.default.hex}}
      BorderColor={{colors.outline_variant.default.hex}}
      BorderWidth=2

      [InputPanel/Background/Margin]
      Left=2
      Right=2
      Top=2
      Bottom=2

      [InputPanel/Highlight]
      Color={{colors.primary_container.default.hex}}

      [InputPanel/Highlight/Margin]
      Left=5
      Right=5
      Top=5
      Bottom=5

      [Menu]
      NormalColor={{colors.on_surface.default.hex}}
      HighlightCandidateColor={{colors.on_primary_container.default.hex}}

      [Menu/Background]
      Color={{colors.surface_container_low.default.hex}}
      BorderColor={{colors.outline_variant.default.hex}}
      BorderWidth=2

      [Menu/Background/Margin]
      Left=2
      Right=2
      Top=2
      Bottom=2

      [Menu/ContentMargin]
      Left=2
      Right=2
      Top=2
      Bottom=2

      [Menu/Highlight]
      Color={{colors.primary_container.default.hex}}

      [Menu/Highlight/Margin]
      Left=5
      Right=5
      Top=5
      Bottom=5

      [Menu/Separator]
      Color={{colors.outline_variant.default.hex}}

      [Menu/TextMargin]
      Left=5
      Right=5
      Top=5
      Bottom=5
''
    ;
    force = true;
  };

  # DMS → fcitx5 配色自动同步
  #
  #   fcitx5 自动跟随 DMS 壁纸配色的同步脚本 + systemd path 单元。
  #   当 DMS 更新配色文件时，自动重写 fcitx5 的 theme.conf 并通知
  #   fcitx5 重新加载，保持输入法配色始终匹配当前壁纸提取的 DMS 动态配色。
  # ============================================================================

  home.file."${config.home.homeDirectory}/.local/bin/dms-fcitx5-sync" = {
    executable = true;
    source = pkgs.writeShellScript "dms-fcitx5-sync" ''
      DMS_CLR="${config.home.homeDirectory}/.cache/DankMaterialShell/dms-colors.json"
      DMS_SES="${config.home.homeDirectory}/.local/state/DankMaterialShell/session.json"
      OUT_DIR="${config.home.homeDirectory}/.local/share/fcitx5/themes/dms"
      OUT="$OUT_DIR/theme.conf"

      [[ -f "$DMS_CLR" && -f "$DMS_SES" ]] || exit 0

      IS_LIGHT=$(${pkgs.jq}/bin/jq -r '.isLightMode // true' < "$DMS_SES")
      SCHEME=$([ "$IS_LIGHT" = "true" ] && echo "light" || echo "dark")
      c() { ${pkgs.jq}/bin/jq -r ".colors.$SCHEME.$1 // \"#000000\"" < "$DMS_CLR"; }

      OS=$(c on_surface); OP=$(c on_primary); PR=$(c primary)
      PC=$(c primary_container); OPC=$(c on_primary_container)
      SCL=$(c surface_container_low); OV=$(c outline_variant)

      mkdir -p "$OUT_DIR"

      cat > "$OUT" << XXXX
      [Metadata]
      Name=DMS Dynamic ($SCHEME)
      Version=1
      Author=DankMaterialShell (auto-sync)
      Description=DMS dynamic theme - $SCHEME scheme
      ScaleWithDPI=True

      [InputPanel]
      NormalColor=$OS
      HighlightCandidateColor=$OP
      HighlightColor=$PR
      HighlightBackgroundColor=$PR
      PageButtonAlignment=Last Candidate

      [InputPanel/TextMargin]
      Left=5
      Right=5
      Top=5
      Bottom=5

      [InputPanel/ContentMargin]
      Left=2
      Right=2
      Top=2
      Bottom=2

      [InputPanel/Background]
      Color=$SCL
      BorderColor=$OV
      BorderWidth=2

      [InputPanel/Background/Margin]
      Left=2
      Right=2
      Top=2
      Bottom=2

      [InputPanel/Highlight]
      Color=$PC

      [InputPanel/Highlight/Margin]
      Left=5
      Right=5
      Top=5
      Bottom=5

      [Menu]
      NormalColor=$OS
      HighlightCandidateColor=$OPC

      [Menu/Background]
      Color=$SCL
      BorderColor=$OV
      BorderWidth=2

      [Menu/Background/Margin]
      Left=2
      Right=2
      Top=2
      Bottom=2

      [Menu/ContentMargin]
      Left=2
      Right=2
      Top=2
      Bottom=2

      [Menu/Highlight]
      Color=$PC

      [Menu/Highlight/Margin]
      Left=5
      Right=5
      Top=5
      Bottom=5

      [Menu/Separator]
      Color=$OV

      [Menu/TextMargin]
      Left=5
      Right=5
      Top=5
      Bottom=5
      XXXX

      kill -SIGUSR1 $(${pkgs.procps}/bin/pgrep -x fcitx5) 2>/dev/null || true
    '';
  };

  systemd.user.services.dms-fcitx5-sync = {
    Unit = { Description = "Sync DMS wallpaper colors to fcitx5 theme"; };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/bin/dms-fcitx5-sync";
    };
  };

  systemd.user.paths.dms-fcitx5-sync = {
    Unit = { Description = "Watch DMS colors and sync to fcitx5 theme"; };
    Path = {
      PathModified = [
        "%h/.cache/DankMaterialShell/dms-colors.json"
        "%h/.local/state/DankMaterialShell/dms-colors.json"
      ];
    };
    Install = { WantedBy = [ "default.target" ]; };
  };
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
