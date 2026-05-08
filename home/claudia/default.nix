{ config, pkgs, inputs, lib, ... }:

# ==============================================================================
# Home Manager —— 用户：claudia（总入口）
#
#   本文件是用户级配置的总入口，通过 imports 引入各子模块。
#   每个子模块负责一个独立的配置领域：
#
#   - shell.nix       → fish + starship + zoxide + kitty（终端环境）
#   - git.nix         → Git 版本控制配置
#   - nvim.nix        → CookNixvim（Neovim 编辑器）
#   - niri.nix        → niri Wayland 合成器（KDL 键绑定/窗口规则）
#   - xdg.nix         → XDG 基础（mimeapps、user-dirs、Xresources）
#   - fcitx5.nix      → Fcitx5 输入法 + DMS 动态配色同步
#   - fuzzel.nix      → Fuzzel 启动器 + DMS 配色同步
#   - gtk-sync.nix    → DMS → GTK 深浅主题同步 + Remmina 包装
#   - dms-fix.nix     → DMS 启动主题修复（自动深浅切换未触发问题）
#   - packages.nix    → 用户级软件包
#   - mpv.nix         → MPV 视频播放器配置
#   - thunar.nix      → Thunar 桌面集成（exo-open、xfconf）
# ==============================================================================

{
  # 导入子模块 —— 按程序/功能拆分，方便维护
  imports = [
    ./shell.nix       # Shell 环境（fish / starship / zoxide / kitty）
    ./ghostty.nix     # Ghostty 终端模拟器（GPU 加速，匹配 Kitty 配置）
    ./fastfetch.nix   # Fastfetch 系统信息显示（Catnap 风格，终端启动自动运行）
    ./git.nix         # Git 版本控制配置
    ./nvim.nix        # CookNixvim（Neovim 编辑器配置）
    ./niri.nix        # niri Wayland 合成器配置
    ./xdg.nix         # XDG 基础配置（mimeapps、user-dirs、Xresources）

    # --- DMS 动态主题同步服务 ---
    ./fcitx5.nix      # Fcitx5 输入法 + DMS 动态配色同步
    ./fuzzel.nix      # Fuzzel 启动器 + DMS 配色同步
    ./gtk-sync.nix    # DMS → GTK 深浅主题同步 + Remmina 包装
    ./dms-fix.nix     # DMS 启动主题修复（SIGUSR1 触发 QML 重载）

    # --- 应用配置 ---
    ./packages.nix    # 用户级软件包
    ./mpv.nix         # MPV 视频播放器配置
    ./thunar.nix      # Thunar 桌面集成（exo-open、xfconf）
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
  # 将 ~/.local/bin 加入 PATH，确保 remmina 包装脚本优先于系统包
  # ============================================================================
  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];
}
