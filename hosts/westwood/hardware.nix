{ config, lib, pkgs, ... }:

# ==============================================================================
# 硬件配置
#
#   本文件管理 westwood 主机的硬件相关设置，涵盖四个方面：
#
#   1. 引导加载器（Bootloader）
#      UEFI + systemd-boot：简单可靠的现代引导方案
#
#   2. NVIDIA Optimus 混合显卡
#      Intel UHD 610（集显，00:02.0）→ 日常显示与轻负载
#      NVIDIA GTX 1650 Ti（独显，01:00.0）→ 按需渲染（游戏/创作）
#      方案：PRIME Render Offload（默认集显，nvidia-offload 命令调用独显）
#
#   3. 蓝牙
#      bluez 协议栈驱动，由 DMS 桌面管理（详见 desktop.nix）
#
#   4. 交换空间
#      zram（压缩内存交换，ZSTD，50% RAM）优先级 100
#      swapfile（16GiB 磁盘后备）优先级 10
#      禁用 zswap（与 zram 功能冲突）
# ==============================================================================

{
  # ============================================================================
  # systemd-boot 引导加载器
  #   使用 UEFI 模式，管理 /boot 分区中的引导条目
  #   canTouchEfiVariables 允许在安装时自动配置 EFI 变量
  # ============================================================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ============================================================================
  # NVIDIA Optimus 混合显卡配置
  #   PRIME Render Offload 方案：
  #     集显 → 显示器输出（默认 GPU）
  #     独显 → 渲染卸载（仅运行 NVIDIA 应用时激活）
  #   使用方式：nvidia-offload <command>
  #   验证：nvidia-offload nvidia-smi
  # ============================================================================

  # 硬件加速图形 —— 启用 OpenGL/Vulkan/VAAPI 加速
  hardware.graphics = {
    enable = true;
    enable32Bit = true;                            # 32 位应用兼容（Steam/Wine 需要）
  };

  # NVIDIA 专有驱动
  hardware.nvidia = {
    # 使用当前内核对应的稳定版 NVIDIA 驱动
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    open = false;                                   # 闭源内核模块（GTX 1650 Ti 不支持 nvidia-open）
    modesetting.enable = true;                      # 内核模式设置 —— 解决屏幕撕裂，支持 Wayland

    # PRIME Render Offload（默认集显，按需调用独显）
    prime = {
      offload.enable = true;                        # 启用卸载渲染
      offload.enableOffloadCmd = true;              # 添加 nvidia-offload 快捷命令
      intelBusId = "PCI:0:2:0";                    # 集显 BusID（lspci 输出 00:02.0）
      nvidiaBusId = "PCI:1:0:0";                   # 独显 BusID（lspci 输出 01:00.0）
    };

    # 电源管理 —— 独显空闲时自动关闭
    powerManagement.enable = true;
    powerManagement.finegrained = true;

    nvidiaSettings = true;                          # 提供 nvidia-settings 图形配置工具
  };

  # X11 视频驱动 —— 优先使用 NVIDIA
  services.xserver.videoDrivers = ["nvidia"];

  # 禁用 nouveau（开源驱动，与 NVIDIA 专有驱动冲突）
  boot.blacklistedKernelModules = ["nouveau"];

  # ============================================================================
  # 蓝牙配置
  #   bluez 协议栈提供底层蓝牙支持
  #   上层管理由 DMS（DankMaterialShell）通过 bluez DBus API 直接操控
  #   DMS 自带蓝牙管理界面 → 不需要额外安装 blueman
  # ============================================================================
  hardware.bluetooth = {
    enable = true;                                  # 启用蓝牙硬件
    powerOnBoot = true;                             # 开机自动开启蓝牙适配器
  };

  # ============================================================================
  # 交换空间 —— zram（优先）+ 16GiB swapfile（后备）
  #
  #   zram 将部分 RAM 压缩后作为交换设备（ZSTD 压缩），
  #   速度远快于磁盘交换，适用于内存敏感的场景。
  #   当 zram 满载后，系统自动溢出到 swapfile。
  #
  #   优先级设计：
  #     zram     priority=100（优先使用）
  #     swapfile priority=10 （后备方案）
  # ============================================================================

  # 禁用 zswap —— 与 zram 功能重叠，两者冲突
  boot.kernelParams = ["zswap.enabled=0"];

  # zram —— 内存压缩交换（速度快，优先使用）
  zramSwap = {
    enable = true;
    algorithm = "zstd";                            # ZSTD 压缩算法（平衡速度与压缩率）
    memoryPercent = 50;                            # 最多占用 50% 内存
    priority = 100;                                # 高优先级，系统优先使用 zram
    swapDevices = 1;                               # 创建 1 个 zram 设备
  };

  # swapfile —— 16GiB 磁盘后备交换（zram 溢出后使用）
  swapDevices = [
    {
      device = "/swapfile";
      size = 16384;                                # 16 GiB
      priority = 10;                               # 低优先级，仅当 zram 不足时使用
    }
  ];
}
