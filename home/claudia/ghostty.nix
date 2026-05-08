{ config, pkgs, ... }:

# ==============================================================================
# Ghostty 终端模拟器配置
#
#   本文件管理 Ghostty 终端模拟器的用户级配置，
#   所有选项均与现有 Kitty 配置保持一致，涵盖：
#   - 字体：JetBrainsMono Nerd Font，大小 13pt
#   - 透明度：85% 背景不透明度（需要 Wayland 合成器支持）
#   - 窗口装饰：隐藏标题栏（由 niri WM 管理）
#   - 光标：方块光标、输入时隐藏鼠标
#   - 内边距：水平/垂直各 5 像素
#   - Shell 集成：禁用光标形状变更（保留方块光标）
#
#   Ghostty 配置通过 programs.ghostty.settings 写入
#   ~/.config/ghostty/config，语法为 key = value。
#   参考：https://ghostty.org/docs/config/reference
# ==============================================================================

{
  # ============================================================================
  # Ghostty 终端模拟器
  #
  #   Ghostty 是新一代 GPU 加速终端，原生 GTK 集成，
  #   兼容 Wayland 透明度和 niri 窗口管理器。
  # ============================================================================
  programs.ghostty = {
    enable = true;

    # Fish Shell 集成（自动注入命令执行标记、提示符标记等）
    enableFishIntegration = true;

    # 安装 bat 的 Ghostty 配置语法高亮
    installBatSyntax = true;

    # 安装 Vim 的 Ghostty 配置语法高亮
    installVimSyntax = true;

    # ==========================================================================
    # Ghostty 终端设置
    #
    #   以下所有 key = value 将写入 ~/.config/ghostty/config。
    #   配置项含义见行尾注释。
    # ==========================================================================
    settings = {
      # ---- 字体 ----
      font-family = "JetBrainsMono Nerd Font";   # 等宽 + Nerd Font 图标
      font-size = 13;                              # 字体大小（pt），与 Kitty 一致

      # ---- 背景透明度 ----
      # 0.85 即 85% 不透明（15% 透明），与 Kitty 的 background_opacity 0.85 一致
      background-opacity = 0.85;

      # ---- 窗口内边距 ----
      window-padding-x = 5;                        # 水平内边距（像素）
      window-padding-y = 5;                        # 垂直内边距（像素）

      # ---- 窗口装饰 ----
      window-decoration = "none";                   # 隐藏标题栏，由 niri WM 管理装饰

      # ---- 关闭确认 ----
      confirm-close-surface = false;                # 关闭窗口时不弹出确认对话框

      # ---- 光标行为 ----
      cursor-style = "block";                       # 方块光标（默认值，显式声明以匹配 Kitty）
      cursor-style-blink = false;                   # 禁用光标闪烁
      mouse-hide-while-typing = true;               # 输入时隐藏鼠标（对应 Kitty cursor_trail）

      # ---- Shell 集成 ----
      # no-cursor 禁用 Ghostty Shell 集成的光标形状变更，
      # 保持方块光标恒定，对应 Kitty 的 shell_integration no-cursor
      shell-integration-features = "no-cursor";
    };
  };
}
