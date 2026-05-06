{ config, lib, pkgs, ... }:

# ==============================================================================
# 共享模块（common）
#   本文件包含所有主机共享的通用配置。
#   如果将来有多台机器，只需在各自的 configuration.nix 中 import 此模块。
# ==============================================================================

{
  # ============================================================================
  # Nix 设置 —— 国内镜像加速
  #   使用 USTC / 清华镜像源替代官方 cache.nixos.org，提高国内下载速度
  # ============================================================================
  nix.settings = {
    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    auto-optimise-store = true;
  };

  # ============================================================================
  # 自动垃圾回收：每天运行，删除 7 天前的世代，最少保留 3 个
  # ============================================================================
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
    persistent = true;
  };

  # 系统 profile 保留至少 3 个世代
  systemd.services.nix-gc-keep = {
    description = "Keep at least 3 Nix generations";
    after = [ "nix-gc.service" ];
    script = ''
      # 保留系统 profile 最新 3 个世代
      ${pkgs.nix}/bin/nix-env --profile /nix/var/nix/profiles/system --delete-generations +3 2>/dev/null || true
      # 保留用户 profile 最新 3 个世代
      ${pkgs.nix}/bin/nix-env --profile /nix/var/nix/profiles/per-user/claudia/profile --delete-generations +3 2>/dev/null || true
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    startAt = "daily";
  };

  # ============================================================================
  # 允许非自由软件（如 NVIDIA 驱动、VS Code、Steam 等）
  # ============================================================================
  nixpkgs.config.allowUnfree = true;

  # ============================================================================
  # 用户定义
  # ============================================================================
  users.users.claudia = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "libvirtd" ];
    shell = pkgs.fish;  # fish 默认登录 Shell
  };

  # ============================================================================
  # 安全设置
  #   wheel 组用户执行 sudo 不需要密码（方便日常使用）
  # ============================================================================
  security.sudo.wheelNeedsPassword = false;
}

