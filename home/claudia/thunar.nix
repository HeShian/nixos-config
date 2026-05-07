{ config, pkgs, lib, ... }:

# ==============================================================================
# Thunar 桌面集成（用户级配置）
#
#   本文件管理 Thunar 文件管理器的用户级配置，包括：
#   - exo-open helpers.rc（终端模拟器设置）
#   - Thunar 默认终端配置（xfconf）
#   - exo-open 终端模拟器（xfce4-appfinder）
#
#   系统级 Thunar 配置（程序包、插件）请见 hosts/westwood/thunar.nix
# ==============================================================================

{
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
    ${pkgs.xfconf}/bin/xfconf-query -c thunar -p /default-terminal-emulator -s kitty 2>/dev/null || \
    ${pkgs.xfconf}/bin/xfconf-query -c thunar -p /default-terminal-emulator -n -t string -s kitty
    ${pkgs.xfconf}/bin/xfconf-query -c xfce4-appfinder -p /terminal-emulator/emulator -s kitty 2>/dev/null || \
    ${pkgs.xfconf}/bin/xfconf-query -c xfce4-appfinder -p /terminal-emulator/emulator -n -t string -s kitty
  '';
}
