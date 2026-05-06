{ config, pkgs, ... }:

# ==============================================================================
# XDG 基础配置
#   管理桌面入口关联（mimeapps.list）、用户目录（user-dirs.dirs）、Xresources
#   这些文件原本在 ~/ 下手动维护，迁移至 HM 后实现声明式管理
# ==============================================================================

{
  # ============================================================================
  # MIME 类型与应用关联
  #   生成 ~/.config/mimeapps.list
  # ============================================================================
  xdg.mimeApps = {
    enable = true;

    # 默认应用 —— 双击文件/链接时启动的程序
    defaultApplications = {
      # Web 链接 → Firefox
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/chrome" = "firefox.desktop";
      "text/html" = "firefox.desktop";
      "application/x-extension-htm" = "firefox.desktop";
      "application/x-extension-html" = "firefox.desktop";
      "application/x-extension-shtml" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "application/x-extension-xhtml" = "firefox.desktop";
      "application/x-extension-xht" = "firefox.desktop";

      # Telegram 链接
      "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
      "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
    };
  };

  # ============================================================================
  # XDG 用户目录
  #   生成 ~/.config/user-dirs.dirs
  #   也可设定 XDG_*_DIR 环境变量，确保各应用能找到对应目录
  # ============================================================================
  xdg.userDirs = {
    enable = true;
    createDirectories = true;                     # 自动创建缺失的目录

    desktop = "$HOME/Desktop";
    download = "$HOME/Downloads";
    templates = "$HOME/Templates";
    publicShare = "$HOME/Public";
    documents = "$HOME/Documents";
    music = "$HOME/Music";
    pictures = "$HOME/Pictures";
    videos = "$HOME/Videos";

    # 保持 XDG 用户目录环境变量向后兼容
    # home.stateVersion < 26.05 时默认值从 true 改为 false
    # 显式设回 true 以保持当前行为并消除 eval 警告
    setSessionVariables = true;
  };

  # ============================================================================
  # Xresources —— X11 应用光标主题
  #   niri 已通过环境变量 XCURSOR_THEME/XCURSOR_SIZE 设定光标，
  #   但 XWayland 下的 X11 应用仍需 .Xresources 中的配置
  # ============================================================================
  home.file."./.Xresources" = {
    text = ''
      Xcursor.theme: Adwaita
      Xcursor.size: 24
    '';
    force = true;
  };
}
