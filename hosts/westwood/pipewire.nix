{ config, lib, pkgs, ... }:

# ==============================================================================
# PipeWire 音频服务
#
#   本文件管理 westwood 主机的音频/视频路由服务。
#
#   PipeWire 替代传统的 PulseAudio + ALSA 组合，提供：
#   - 低延迟音频（适合音乐制作和游戏）
#   - 自动蓝牙音频切换（A2DP/HSP）
#   - 屏幕录制的音频采集（kooha 等应用依赖）
#   - Flatpak 应用的音频支持
# ==============================================================================

{
  services.pipewire = {
    enable = true;
    alsa.enable = true;                          # ALSA 兼容层（传统应用）
    pulse.enable = true;                         # PulseAudio 兼容层
    wireplumber.enable = true;                   # WirePlumber 会话管理
  };
}
