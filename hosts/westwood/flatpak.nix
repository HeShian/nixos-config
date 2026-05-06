{ config, lib, pkgs, ... }:

# ==============================================================================
# Flatpak 配置
#   启用 Flatpak 包管理框架 + 中科大 USTC Flathub 镜像源
#   flatpak 会自动纠正 "flathub" 远程到官方 URL，因此先添加再通过
#   remote-modify 改回 USTC 镜像地址
# ==============================================================================

{
  # ============================================================================
  # Flatpak 服务
  # ============================================================================
  services.flatpak.enable = true;

  # ============================================================================
  # 开机自动添加 Flathub 远程仓库（中科大 USTC 镜像 + GPG 验证）
  #   flatpak 会将名为 "flathub" 的远程自动纠正到官方 URL，
  #   因此需要额外一步 remote-modify 改回镜像地址。
  #   --no-gpg-verify 会导致安装应用时报错"无法从不信任的远程仓库提取"，
  #   必须导入 Flathub GPG 公钥启用签名验证。
  # ============================================================================
  systemd.services.flatpak-configure-ustc = {
    description = "Add Flathub remote with USTC mirror and GPG verification";
    wantedBy = [ "multi-user.target" ];
    after = [ "flatpak-system-helper.service" "network-online.target" ];
    wants = [ "flatpak-system-helper.service" "network-online.target" ];
    script = ''
      # 下载 Flathub GPG 公钥（flatpak 官方仓库的签名密钥）
      ${pkgs.curl}/bin/curl -fLSs -o /tmp/flathub.gpg \
        https://flathub.org/repo/flathub.gpg

      # 添加远程仓库（带 GPG 验证）
      # 注：flatpak 会在添加后自动纠正 URL 到官方地址（dl.flathub.org）
      ${pkgs.flatpak}/bin/flatpak remote-add \
        --gpg-import=/tmp/flathub.gpg \
        --if-not-exists --system flathub https://mirrors.ustc.edu.cn/flathub

      # 重新改回 USTC 镜像地址，覆盖 flatpak 的自动纠正
      ${pkgs.flatpak}/bin/flatpak remote-modify \
        --url=https://mirrors.ustc.edu.cn/flathub flathub

      # 清理临时 GPG 密钥
      rm -f /tmp/flathub.gpg
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}
