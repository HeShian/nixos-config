{ config, lib, pkgs, ... }:

# ==============================================================================
# 引导加载器 —— systemd-boot
#
#   本文件管理 westwood 主机的系统引导配置。
#
#   引导方案：UEFI + systemd-boot
#   systemd-boot 是 systemd 生态的一部分，简单可靠，
#   自动管理 /boot 分区中的引导条目。
#
#   canTouchEfiVariables = true 允许在 nixos-rebuild 时自动配置 EFI 变量，
#   使 systemd-boot 成为默认引导项。
# ==============================================================================

{
  # ============================================================================
  # systemd-boot 引导加载器
  # ============================================================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
