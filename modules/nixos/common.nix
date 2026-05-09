{ config, lib, pkgs, ... }:

# ==============================================================================
# 共享模块（common）
#
#   本文件包含所有主机共享的通用 NixOS 配置，适用于单机或多机场景。
#   当前只管理 westwood 一台主机，但仍然保持模块化结构。
#
#   如果将来增加多台机器，只需在新主机的 configuration.nix 中 import 本模块。
#
#   本模块涵盖：
#   - Nix 设置：国内镜像加速（USTC/清华镜像源）、store 自动优化
#   - 垃圾回收：自动 GC + 世代保留策略
#   - 用户定义：系统用户 claudia 及其用户组
#   - 安全设置：wheel 组 sudo 免密码
#   - 非自由软件许可：允许 unfree 包（NVIDIA 驱动、Steam 等）
# ==============================================================================

{
  # ============================================================================
  # Nix 设置 —— 国内镜像加速
  #
  #   替换官方 cache.nixos.org 为国内镜像源以提高下载速度。
  #
  #   镜像源优先级：USTC（主）→ 清华（备用）→ cache.nixos.org（回退）
  #
  #   auto-optimise-store = true：
  #     自动对 /nix/store 中的相同文件进行硬链接去重，
  #     节省磁盘空间，建议 SSD 用户启用。
  # ============================================================================
  nix.settings = {
    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"        # 中科大镜像（主）
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" # 清华镜像（备用）
      "https://cache.nixos.org/"                               # 官方源（最终回退）
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    auto-optimise-store = true;                               # store 自动去重优化
    experimental-features = [ "nix-command" "flakes" ];          # 启用 nix 命令（nix run/search 等）和 Flake 支持
  };

  # ============================================================================
  # Nix 垃圾回收（GC）
  #
  #   两层清理策略：
  #   1. nix.gc：自动删除超过 7 天的旧 generations
  #   2. nix-gc-keep：在上述清理之后，确保系统/用户 profile 各保留至少 3 个世代
  #
  #   每天运行一次，避免无限制堆积占用磁盘空间。
  # ============================================================================
  nix.gc = {
    automatic = true;                                          # 启用自动 GC
    dates = "daily";                                           # 每天执行
    options = "--delete-older-than 7d";                        # 删除 7 天前的世代
    persistent = true;                                         # 即使系统休眠也补执行
  };

  # 保留至少 3 个系统/用户世代（在 GC 之后运行）
  systemd.services.nix-gc-keep = {
    description = "保留至少 3 个 Nix 世代";
    after = [ "nix-gc.service" ];                              # 在 GC 之后执行
    script = ''
      # 保留系统 profile 最新 3 个世代
      ${pkgs.nix}/bin/nix-env --profile /nix/var/nix/profiles/system --delete-generations +3 2>/dev/null || true
      # 保留用户 claudia 的 profile 最新 3 个世代
      ${pkgs.nix}/bin/nix-env --profile /nix/var/nix/profiles/per-user/claudia/profile --delete-generations +3 2>/dev/null || true
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    startAt = "daily";
  };

  # ============================================================================
  # 允许非自由软件
  #   必须启用，否则以下包无法安装：
  #   - NVIDIA 专有驱动
  #   - Steam
  #   - VS Code
  #   - Discord / QQ / WeChat 等
  # ============================================================================
  nixpkgs.config.allowUnfree = true;

  # ============================================================================
  # 系统用户定义 —— claudia
  #
  #   isNormalUser：创建标准用户（自动生成 home 目录、UID 等）
  #   extraGroups 中的组决定了用户的权限范围：
  #     wheel         → sudo 权限
  #     networkmanager → 管理网络连接的权限
  #     libvirtd      → 管理 KVM 虚拟机的权限
  #   shell：登录 Shell 设为 fish（需先在 programs.fish 中启用，见 packages.nix）
  # ============================================================================
  users.users.claudia = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "libvirtd" ];
    shell = pkgs.fish;                                         # 默认登录 Shell
  };

  # ============================================================================
  # 安全设置
  #   wheelNeedsPassword = false → wheel 组用户执行 sudo 不需要密码
  #   方便日常操作，但降低了安全性（物理接触此机器的人可直接 sudo）
  #   如果对安全性有更高要求，请设为 true（默认值）
  # ============================================================================
  security.sudo.wheelNeedsPassword = false;
}
