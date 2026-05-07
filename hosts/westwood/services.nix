{ config, lib, pkgs, ... }:

# ==============================================================================
# 系统服务配置
#
#   本文件管理 westwood 主机的系统级服务，与 packages.nix 分离，
#   让系统软件包和系统服务各司其职。
#
#   配置内容：
#   - v2raya：用户态代理客户端（Web 面板管理）
#   - libvirtd：KVM/QEMU 虚拟化
#   - daed：基于 eBPF 的内核态代理
# ==============================================================================

{
  # ============================================================================
  # V2RayA —— 用户态代理客户端
  #   提供 Web 面板管理代理规则和节点切换
  # ============================================================================
  services.v2raya.enable = true;

  # ============================================================================
  # libvirtd（KVM/QEMU 虚拟化）
  #
  #   完整的虚拟化解决方案，支持：
  #   - KVM 硬件加速（需要 CPU 支持 VT-x/AMD-V）
  #   - QEMU 全虚拟化
  #   - virt-manager 图形管理（用户级包，见 home/claudia/packages.nix）
  #   用户 virt-manager 非 root 管理需要用户加入 libvirtd 组
  #   （已在 modules/nixos/common.nix 中配置）
  # ============================================================================
  virtualisation.libvirtd.enable = true;

  # ============================================================================
  # Daed —— 基于 eBPF 的内核态代理
  #
  #   daed 是 dae 的升级版，在 Linux 内核 eBPF 层面进行流量代理，
  #   CPU/内存开销远低于用户态代理。Web 管理面板端口：2023
  #
  #   v2raya（用户态）和 daed（内核态）可以共存，
  #   两者使用不同的端口和路由规则，互不干扰。
  # ============================================================================
  systemd.packages = with pkgs; [ daed ];
  systemd.services.daed.wantedBy = [ "multi-user.target" ];
  systemd.services.daed.environment.DAE_LOCATION_ASSET =
    "${pkgs.symlinkJoin {
      name = "dae-assets";
      paths = with pkgs; [ v2ray-geoip v2ray-domain-list-community ];
    } }/share/v2ray";
  networking.firewall.allowedTCPPorts = [ 2023 ]; # daed Web 管理面板端口
}
