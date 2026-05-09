{ config, lib, pkgs, ... }:

# ==============================================================================
# 系统软件包配置
#
#   本文件管理 westwood 主机的系统级软件包（对所有用户可用）。
#   用户级软件包（仅 claudia 可用，不需要 root 权限）请见：
#     /etc/nixos/home/claudia/packages.nix → home.packages
#
#   系统服务（v2raya / libvirtd / daed）请见 services.nix
#
#   配置分类：
#   - 系统级程序（programs.*）：Firefox、Fish、Steam、VSCode
#   - 系统级软件包（environment.systemPackages）：一般工具和开发环境
# ==============================================================================

{
  # ============================================================================
  # 系统级程序（programs.*）
  #   NixOS 模块级程序配置，比直接在 systemPackages 中添加更完整
  #   （自动处理配置文件、D-Bus 激活、systemd 单元等）
  # ============================================================================
  programs.firefox.enable = true;                  # Firefox 浏览器（带 NixOS 集成）
  programs.fish.enable = true;                     # Fish Shell（系统级启用，确保 /etc/shells 注册）
  programs.vscode.enable = true;                   # VSCode 编辑器（含 extensions 支持）

  # ============================================================================
  # Steam 游戏平台
  #   extest.enable：Wayland 下 Steam Input 手柄支持
  #   remotePlay：Steam 远程同乐/串流防火墙放行
  #   dedicatedServer：Steam 独立服务器防火墙放行
  # ============================================================================
  programs.steam = {
    enable = true;
    extest.enable = true;                          # Wayland 下 Steam Input 手柄支持
    remotePlay.openFirewall = true;                # Steam 远程同乐
    dedicatedServer.openFirewall = true;           # Steam 独立服务器
  };

  # ============================================================================
  # 系统级软件包（environment.systemPackages）
  #
  #   以下包对所有系统用户可用（包括 root 和未来新增的用户）。
  #   如果某个包仅当前用户需要，请放入 home.packages（home/claudia/default.nix）。
  #
  #   包分组说明：
  #   - 基础工具：google-chrome / kazumi / neovim / git / wget / curl / opencode
  #   - 开发运行时：nodejs / bun / uv / python3
  #   - 桌面集成：fuzzel（启动器）/ qt5ct/qt6ct / adwaita-icon-theme
  #   - 虚拟化：qemu_kvm（virt-manager 检测 QEMU 需要 qemu-kvm 可用）
  #   - 多媒体：gstreamer / obs-studio
  #   - Wine 兼容层：wine / winetricks
  #   - 代理：daed
  #
  #   注：libvirtd 服务配置见 services.nix（含 SWTPM、QEMU 符号链接等）
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # ---- 基础工具 ----
    google-chrome                                 # Google Chrome 浏览器
    kazumi                                        # 在线动漫播放器（弹幕支持）
    neovim                                       # 终端编辑器（主力）
    git                                          # 版本控制系统
    wget                                         # HTTP/FTP 文件下载
    curl                                         # HTTP 命令行工具
    unzip                                        # ZIP 解压工具
    unrar                                        # RAR 解压工具（Thunar 右键解压依赖）
    p7zip                                        # 7z 压缩/解压支持
    xarchiver                                    # GTK 归档管理器（Thunar 右键解压依赖）
    thunar-archive-plugin                        # Thunar 右键归档菜单插件
    opencode                                     # AI 编码代理（终端版）
    hardinfo2                                    # 系统信息与基准测试工具（硬件检测/性能评估）
    tree                                         # 目录树可视化工具

    # ---- 开发运行时 ----
    nodejs                                       # JavaScript/TypeScript 运行时
    bun                                          # 快速 JS/TS 工具链（兼容 Node.js API）
    uv                                           # Python 包管理器（astral.sh 出品，替代 pip/poetry）
    python3                                      # Python 3 解释器

    # ---- 桌面集成 ----
    fuzzel                                        # 应用启动器（Mod+Z 快捷键，系统级确保 PATH 可见）
    libsForQt5.qt5ct                             # Qt5 配置工具（DMS 应用 Qt 配色用）
    kdePackages.qt6ct                            # Qt6 配置工具
    adwaita-icon-theme                           # Adwaita 图标 & 光标主题（DMS 依赖）
    gsettings-desktop-schemas                    # GNOME 接口 schema（使 color-scheme、gtk-theme 等 gsettings 键生效，对所有 GTK3/4 应用深浅主题切换至关重要）

    # ---- 虚拟化 ----
    qemu_kvm                                     # QEMU KVM 硬件加速虚拟化（提供 qemu-kvm/qemu-system-x86_64）

    # ---- 多媒体 ----
    gst_all_1.gstreamer                          # GStreamer 多媒体框架工具（gst-inspect / gst-launch）
    obs-studio                                   # OBS Studio 录屏/推流（niri DMA-BUF 兼容）

    # ---- Wine 兼容层 ----
    winePackages.unstableFull                    # Wine Windows 兼容层（完整版，含所有依赖）
    winetricks                                   # Wine 辅助脚本（安装 DLL/组件）

    # ---- 代理 ----
    daed                                         # eBPF 内核态代理 + Web 管理面板
  ];
}
