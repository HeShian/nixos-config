{ config, lib, pkgs, ... }:

# ==============================================================================
# 交换空间 —— zram（优先）+ 16GiB swapfile（后备）
#
#   本文件管理 westwood 主机的内存交换策略。
#
#   设计原则：
#   zram 将部分 RAM 压缩后作为交换设备（ZSTD 压缩），
#   速度远快于磁盘交换，适用于内存敏感的场景。
#   当 zram 满载后，系统自动溢出到 swapfile。
#
#   优先级设计：
#     zram     priority=100（优先使用，速度快）
#     swapfile priority=10 （后备方案，容量大）
#
#   注意：禁用 zswap（与 zram 功能重叠，两者冲突）
# ==============================================================================

{
  # 禁用 zswap —— 与 zram 功能冲突
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
