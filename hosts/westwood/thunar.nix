{ config, lib, pkgs, ... }:

# ==============================================================================
# Thunar 文件管理器 & 桌面基础服务
#
#   本文件管理 Thunar 轻量文件管理器及其依赖的桌面基础服务。
#
#   配置内容：
#   - Thunar：Xfce 轻量文件管理器
#   - thunar-volman：可移动设备自动挂载
#   - thunar-archive-plugin：右键压缩/解压集成
#   - xfconf：Xfce 设置存储后端（Thunar 依赖）
#   - gvfs：虚拟文件系统（挂载/回收站/网络文件系统）
#   - dconf：GNOME/GTK 应用的设置存储
# ==============================================================================

{
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-volman                              # 可移动设备自动管理
      thunar-archive-plugin                      # 压缩文件集成（右键菜单）
    ];
  };

  programs.xfconf.enable = true;                 # Xfce 设置存储后端（Thunar 依赖）
  services.gvfs.enable = true;                   # GVfs —— 挂载/回收站/网络文件系统支持

  programs.dconf.enable = true;                  # dconf —— GNOME/GTK 应用的设置存储
}
