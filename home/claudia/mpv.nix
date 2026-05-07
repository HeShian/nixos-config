{ config, pkgs, ... }:

# ==============================================================================
# MPV 视频播放器配置
#
#   本文件管理 MPV 播放器的配置（参考 emoeem/mpv 项目适配）。
#
#   配置涵盖：
#   - 视频输出：GPU-Next + NVDEC 硬解（Wayland 兼容）
#   - 高质量缩放：ewa_lanczossharp 缩放算法
#   - HDR 色彩管理：ICC 自动配置
#   - 音频：PipeWire 后端 + 32位浮点
#   - 字幕 & OSD：中文字体、位置优化
#   - Bilibili 弹幕集成（bdanmaku 插件）
# ==============================================================================

{
  home.file.".config/mpv/mpv.conf" = {
    text = ''
      # ======================================================================
      # 视频输出
      # ======================================================================
      vo=gpu-next
      hwdec=nvdec-copy                    # NVIDIA NVDEC 硬解（copy 模式兼容 Wayland）
      hwdec-codecs=all                    # 全部编码格式尝试硬解
      gpu-context=wayland                 # Wayland 输出

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
}
