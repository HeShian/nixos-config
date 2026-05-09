{ config, pkgs, ... }:
let
  # ==============================================================================
  # Ghostty 光标拖尾着色器 — Cursor Warp（Neovide 风格）
  #
  #   从 sahaj-b/ghostty-cursor-shaders 获取 cursor_warp.glsl，
  #   这是一个 Neovide 风格的光标拖尾着色器，通过"扭曲"技术实现平滑拖尾：
  #
  #   核心特性：
  #   - 光标扭曲（Warp）：从旧位置到新位置拉伸光标形状，模拟平滑移动
  #   - 四角独立动画：根据移动方向，光标四角以不同速度移动
  #     · 前导角（Leading）：先到达新位置 → 产生"拖拽"感
  #     · 尾随角（Trailing）：后到达 → 产生"拉伸"感
  #   - 淡出渐变（FADE）：沿拖尾路径从新位置到旧位置渐隐
  #   - 9 种缓动函数可选：EaseOutCirc（默认）、EaseOutCubic、Spring 等
  #   - 方向感知模糊：水平/垂直移动无模糊，对角线移动有抗锯齿
  #   - 最可定制的着色器：动画时长、拖尾大小、粗细、颜色均可调
  #
  #   参考：https://github.com/sahaj-b/ghostty-cursor-shaders
  # ==============================================================================
  ghostty-shaders-src = pkgs.fetchFromGitHub {
    owner = "sahaj-b";
    repo = "ghostty-cursor-shaders";
    rev = "06d4e90fb5410e9c4d0b3131584060adddf89406";
    sha256 = "sha256-G/UIr1bKnxn1AcHl/4FL/jou6b7M2VeREslYVELxdmw=";
  };

  # ==============================================================================
  # 着色器微调：启用淡出渐变
  #
  #   将 FADE_ENABLED 从 0.0 改为 1.0，启用沿拖尾路径的渐隐效果，
  #   这是 Neovide 风格拖尾的标志性特征 —— 尾部逐渐变透明。
  #
  #   其他参数保持默认值（已是 Neovide 风格的最佳实践）：
  #   - DURATION = 0.2s：快速响应，不拖泥带水
  #   - TRAIL_SIZE = 0.8：明显的拖尾拉伸
  #   - EaseOutCirc 缓动：圆润减速，类似 Neovide 的平滑感
  # ==============================================================================
  cursor_warp_shader = pkgs.runCommand "cursor-warp.glsl" {
    nativeBuildInputs = [ pkgs.gnused ];
  } ''
    sed \
      -e 's|const float FADE_ENABLED = 0.0;|const float FADE_ENABLED = 1.0;  // Neovide-style fade gradient|' \
      ${ghostty-shaders-src}/cursor_warp.glsl > $out
  '';
in
# ==============================================================================
# Ghostty 终端模拟器配置
#
#   本文件管理 Ghostty 终端模拟器的用户级配置，
#   所有选项均与现有 Kitty 配置保持一致，涵盖：
#   - 字体：JetBrainsMono Nerd Font，大小 13pt
#   - 透明度：85% 背景不透明度（需要 Wayland 合成器支持）
#   - 窗口装饰：隐藏标题栏（由 niri WM 管理）
#   - 光标：方块光标、输入时隐藏鼠标、Neovide 风格扭曲拖尾动画
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

      # ---- 自定义着色器：Neovide 风格光标扭曲拖尾动画 ----
      # 部署 cursor-warp 着色器到 ~/.config/ghostty/shaders/
      # 扭曲拖尾：四角独立动画 + 拖尾渐隐 + 圆润减速缓动
      custom-shader = "shaders/cursor-warp.glsl";
      # 保持动画持续运行（即使终端未聚焦也继续渲染动画，避免拖尾冻结）
      custom-shader-animation = "always";

      # ---- Shell 集成 ----
      # no-cursor 禁用 Ghostty Shell 集成的光标形状变更，
      # 保持方块光标恒定，对应 Kitty 的 shell_integration no-cursor
      shell-integration-features = "no-cursor";
    };
  };

  # ============================================================================
  # 部署着色器文件
  #
  #   将获取的 cursor-warp.glsl 着色器文件部署到 Ghostty 着色器目录。
  #   Ghostty 的 custom-shader 路径相对于 ~/.config/ghostty/，
  #   因此 settings 中可写 "shaders/cursor-warp.glsl"。
  #   home.file 必须在模块顶层声明，不能嵌套在 programs.ghostty 内。
  # ============================================================================
  home.file.".config/ghostty/shaders/cursor-warp.glsl" = {
    source = "${cursor_warp_shader}";
    executable = false;
  };
}
