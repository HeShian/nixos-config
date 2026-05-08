{ config, pkgs, ... }:

# ==============================================================================
# Fastfetch 系统信息显示配置
#
#   本文件管理 Fastfetch 的用户级配置，
#   参考 szchan/myfastfetch 的 Catnap 风格布局：
#   - 小型 Logo + 系统信息面板并排显示
#   - 显示：用户名、主机名、运行时间、发行版、内核、WM、桌面、终端、Shell
#   - 显示：CPU、磁盘、内存
#   - 底部显示色彩块
#
#   配置写入 ~/.config/fastfetch/config.jsonc
#   参考：https://github.com/fastfetch-cli/fastfetch/wiki/Json-Schema
# ==============================================================================

{
  # ============================================================================
  # Fastfetch —— 系统信息快速概览
  #
  #   终端启动时自动运行（在 fish interactiveShellInit 中配置），
  #   提供系统硬件和软件环境的概览信息。
  #   布局采用 Catnap 风格（两边框线 + 图标 + 中文标签）。
  # ============================================================================
  programs.fastfetch = {
    enable = true;

    settings = {
      # ---- Logo 设置 ----
      logo = {
        type = "small";
        padding.top = 1;
      };

      # ---- 显示设置 ----
      display.separator = " ";

      # ---- 信息模块 ----
      modules = [
        # 顶部边框
        { key = "╭───────────╮"; type = "custom"; }
        # 用户名
        { key = "│ {#31} user    {#keys}│"; type = "title"; format = "{user-name}"; }
        # 主机名
        { key = "│ {#32}󰇅 hname   {#keys}│"; type = "title"; format = "{host-name}"; }
        # 运行时间
        { key = "│ {#33}󰅐 uptime  {#keys}│"; type = "uptime"; }
        # 发行版
        { key = "│ {#34}{icon} distro  {#keys}│"; type = "os"; }
        # 内核
        { key = "│ {#35} kernel  {#keys}│"; type = "kernel"; }
        # 窗口管理器
        { key = "│ {#36} wm      {#keys}│"; type = "wm"; }
        # 桌面环境
        { key = "│ {#36}󰇄 desktop {#keys}│"; type = "de"; }
        # 终端
        { key = "│ {#31} term    {#keys}│"; type = "terminal"; }
        # Shell
        { key = "│ {#32} shell   {#keys}│"; type = "shell"; }
        # CPU（显示性能核数量）
        { key = "│ {#33}󰍛 cpu     {#keys}│"; type = "cpu"; showPeCoreCount = true; }
        # 磁盘
        { key = "│ {#34}󰉉 disk    {#keys}│"; type = "disk"; folders = "/"; }
        # 内存
        { key = "│ {#36} memory  {#keys}│"; type = "memory"; }
        # 分隔线
        { key = "├───────────┤"; type = "custom"; }
        # 色彩块
        { key = "│ {#39} colors  {#keys}│"; type = "colors"; symbol = "circle"; }
        # 底部边框
        { key = "╰───────────╯"; type = "custom"; }
      ];
    };
  };
}
