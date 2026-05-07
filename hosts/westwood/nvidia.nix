{ config, lib, pkgs, ... }:

# ==============================================================================
# NVIDIA Optimus 混合显卡配置
#
#   本文件管理 westwood 主机的 GPU 硬件加速与 NVIDIA 专有驱动。
#
#   硬件信息：
#   - Intel UHD 610（集显，BusID PCI:0:2:0）→ 日常显示与轻负载
#   - NVIDIA GTX 1650 Ti Mobile（独显，BusID PCI:1:0:0）→ 按需渲染
#
#   方案：PRIME Render Offload
#     默认使用集显输出，运行 nvidia-offload <命令> 调用独显渲染。
#     集显 → 显示器输出（默认 GPU）
#     独显 → 渲染卸载（仅运行 NVIDIA 应用时激活）
#
#   验证方式：nvidia-offload nvidia-smi
# ==============================================================================

{
  # ============================================================================
  # 硬件加速图形 —— OpenGL/Vulkan/VAAPI
  # ============================================================================
  hardware.graphics = {
    enable = true;
    enable32Bit = true;                            # 32 位应用兼容（Steam/Wine 需要）
  };

  # ============================================================================
  # NVIDIA 专有驱动
  # ============================================================================
  hardware.nvidia = {
    # 当前内核对应的稳定版驱动
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
}
