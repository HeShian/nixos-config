{ config, pkgs, ... }:

# ==============================================================================
# XDG 基础配置
#
#   本文件管理三个 XDG 相关的配置，实现声明式桌面集成：
#
#   1. mimeapps.list（MIME 类型 → 默认应用关联）
#      双击文件/链接时，系统根据此配置选择启动的程序。
#      例如：http/https 链接 → Firefox，tg:// 链接 → Telegram。
#
#   2. user-dirs.dirs（XDG 用户目录）
#      统一定位桌面/下载/文档等标准目录的位置。
#      很多应用通过 XDG_*_DIR 环境变量寻找这些目录。
#
#   3. Xresources（X11 应用光标主题）
#      XWayland 下的 X11 应用需要 .Xresources 才能正确显示光标。
#      niri 原生 Wayland 客户端的环境变量已由 niri.nix 配置。
#
#   原先这些文件在 ~/ 下手动维护，迁移到 Home Manager 后实现声明式管理。
# ==============================================================================

{
  # ============================================================================
  # MIME 类型与应用关联
  #
  #   生成 ~/.config/mimeapps.list
  #   这是一个自由桌面协会（Freedesktop.org）标准文件，
  #   定义了每种文件类型（MIME type）对应的默认桌面应用。
  # ============================================================================
  xdg.mimeApps = {
    enable = true;

    # 默认应用 —— 双击文件或点击链接时启动的程序
    defaultApplications = {
      # ---- Web 关联（HTTP/HTTPS → Firefox） ----
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

      # ---- Telegram 链接 ----
      "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
      "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";

      # ---- 文本文件 → Neovim（在 kitty 终端中打开） ----
      #   通用文本
      "text/plain" = "nvim.desktop";
      "text/x-readme" = "nvim.desktop";
      "text/x-log" = "nvim.desktop";
      #   编程语言源码
      "text/x-shellscript" = "nvim.desktop";
      "text/x-python" = "nvim.desktop";
      "text/x-csrc" = "nvim.desktop";
      "text/x-c++src" = "nvim.desktop";
      "text/x-c" = "nvim.desktop";
      "text/x-chdr" = "nvim.desktop";
      "text/x-c++hdr" = "nvim.desktop";
      "text/x-makefile" = "nvim.desktop";
      "text/x-nix" = "nvim.desktop";
      "text/x-lua" = "nvim.desktop";
      "text/x-rust" = "nvim.desktop";
      "text/x-go" = "nvim.desktop";
      "text/x-java" = "nvim.desktop";
      "text/x-javascript" = "nvim.desktop";
      "text/x-typescript" = "nvim.desktop";
      "text/css" = "nvim.desktop";
      "text/x-html" = "nvim.desktop";
      "text/x-sql" = "nvim.desktop";
      #   配置文件格式
      "text/x-toml" = "nvim.desktop";
      "text/x-yaml" = "nvim.desktop";
      "text/x-json" = "nvim.desktop";
      "text/x-ini" = "nvim.desktop";
      "text/x-diff" = "nvim.desktop";
      "text/x-patch" = "nvim.desktop";
      #   标记语言
      "text/x-markdown" = "nvim.desktop";
      "text/x-rst" = "nvim.desktop";
      "text/x-tex" = "nvim.desktop";
      #   其他格式
      "application/json" = "nvim.desktop";
      "application/x-shellscript" = "nvim.desktop";
      "application/x-python" = "nvim.desktop";
      "application/xml" = "nvim.desktop";
      "application/x-yaml" = "nvim.desktop";
      "inode/x-empty" = "nvim.desktop";
    };
  };

  # ============================================================================
  # XDG 用户目录
  #
  #   生成 ~/.config/user-dirs.dirs
  #   通过 XDG_*_DIR 环境变量告诉各应用："下载目录在哪里"、"桌面在哪里"等。
  #
  #   createDirectories = true → 自动创建缺失的目录（很有用）
  # ============================================================================
  xdg.userDirs = {
    enable = true;
    createDirectories = true;                       # 自动创建缺失目录

    desktop = "$HOME/Desktop";
    download = "$HOME/Downloads";
    templates = "$HOME/Templates";
    publicShare = "$HOME/Public";
    documents = "$HOME/Documents";
    music = "$HOME/Music";
    pictures = "$HOME/Pictures";
    videos = "$HOME/Videos";

    # 保持 XDG 用户目录环境变量向后兼容
    # home.stateVersion < 26.05 时此值默认从 true 改为 false
    # 显式设为 true 以保持当前行为并消除 eval 警告
    setSessionVariables = true;
  };

  # ============================================================================
  # Xresources —— X11 应用光标主题
  #
  #   niri 本身是 Wayland 合成器，在 environment 中设置了 XCURSOR_THEME 等
  #   环境变量（见 niri.nix），但这只对原生 Wayland 应用有效。
  #
  #   XWayland 下运行的 X11 应用读取 ~/.Xresources 获取光标设置。
  #   此配置确保 XWayland 应用的光标与 Wayland 原生应用一致。
  # ============================================================================
  home.file.".Xresources" = {
    text = ''
      Xcursor.theme: Adwaita
      Xcursor.size: 24
    '';
    force = true;
  };
}
