{ config, lib, pkgs, ... }:

# ==============================================================================
# 硬件配置
#   引导（Bootloader）、NVIDIA Optimus 混合显卡、蓝牙、交换空间
# ==============================================================================

{
  # ============================================================================
  # 引导（Bootloader）
  #   UEFI 模式 + systemd-boot，简单可靠
  # ============================================================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ============================================================================
  # 硬件加速图形 —— NVIDIA Optimus 混合显卡
  #   Intel UHD Graphics 610（集显, 00:02.0）→ 日常显示
  #   NVIDIA GeForce GTX 1650 Ti Mobile（独显, 01:00.0）→ 按需渲染
  #   方案：PRIME Render Offload（省电优先，需要独显时用 nvidia-offload 命令）
  # ============================================================================
  hardware.graphics = {
    enable = true;
    enable32Bit = true;                        # 32 位应用（如 Wine/Steam）硬件加速
  };

  # NVIDIA 专有驱动
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    open = false;                              # 使用闭源内核模块（GTX 1650 Ti 不支持开源）
    modesetting.enable = true;                 # 内核模式设置 —— 解决屏幕撕裂，支持 Wayland

    # PRIME Render Offload —— 默认集显，按需调用独显
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;         # 添加 nvidia-offload 命令
      intelBusId = "PCI:0:2:0";               # lspci 00:02.0
      nvidiaBusId = "PCI:1:0:0";              # lspci 01:00.0
    };

    # 电源管理 —— 独显空闲时自动关闭
    powerManagement.enable = true;
    powerManagement.finegrained = true;

    nvidiaSettings = true;                     # nvidia-settings 图形配置工具
  };

  # X11 视频驱动 —— 优先使用 NVIDIA
  services.xserver.videoDrivers = ["nvidia"];

  # 禁用 nouveau（与 NVIDIA 专有驱动冲突）
  boot.blacklistedKernelModules = ["nouveau"];

  # ============================================================================
  # 蓝牙
  # ============================================================================
  hardware.bluetooth = {
    enable = true;                             # 启用蓝牙硬件
    powerOnBoot = true;                        # 开机自动开启蓝牙
  };

  # ============================================================================
  # 交换空间 —— zram（优先）+ 16G swap 文件（后备）
  #   优先使用 zram（压缩内存交换，速度快），溢出到 swap 文件
  # ============================================================================
  # 禁用 zswap（与 zram 功能重叠，二者取一）
  boot.kernelParams = ["zswap.enabled=0"];

  # zram —— 内存压缩交换，优先级高
  zramSwap = {
    enable = true;
    algorithm = "zstd";                       # 压缩率高且速度快
    memoryPercent = 50;                       # 最多用 50% 内存（约 7.5Gi）
    priority = 100;                           # 高于 swap 文件，优先使用
    swapDevices = 1;                          # 1 个 zram 设备
  };

  # 16G swap 文件 —— 作为后备，zram 溢出后使用
  swapDevices = [
    {
      device = "/swapfile";
      size = 16384;                           # 16GiB
      priority = 10;                          # 低于 zram
    }
  ];
}
