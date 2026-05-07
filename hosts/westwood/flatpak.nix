{ config, lib, pkgs, ... }:

# ==============================================================================
# Flatpak 配置
#
#   本文件管理 Flatpak 容器化应用框架，包括：
#   - Flatpak 系统服务（D-Bus 激活、应用安装支持）
#   - Flathub 远程仓库自动配置（中科大 USTC 镜像 + GPG 签名验证）
#
#   设计说明：
#   Flatpak 会自动将名为 "flathub" 的远程仓库 URL 纠正到官方地址
#   （dl.flathub.org），因此配置分为两步：
#     1. 添加远程仓库（先指向 USTC 镜像，flatpak 会自动纠正到官方）
#     2. 重新修改 URL 为 USTC 镜像地址（覆盖 flatpak 的自动纠正）
#
#   安装 Flatpak 应用示例：
#     flatpak install flathub <应用ID>
#     flatpak install flathub com.spotify.Client
#
#   常用 Flatpak 应用：Spotify、Slack、Figma、OBS Studio（如果需要沙箱隔离版本）
# ==============================================================================

{
  # ============================================================================
  # Flatpak 系统服务
  #   systemd 用户级服务 → flatpak-system-helper.service
  #   提供 D-Bus API，供 flatpak 命令行和软件中心调用
  # ============================================================================
  services.flatpak.enable = true;

  # ============================================================================
  # systemd oneshot 服务 —— 开机自动配置 USTC 镜像
  #
  #   功能：
  #   1. 下载 Flathub 官方 GPG 公钥 → 用于验证包签名
  #   2. 添加 "flathub" 远程仓库（指向 USTC 镜像）
  #   3. 将 URL 重新设为 USTC 镜像（覆盖 flatpak 的自动纠正）
  #
  #   为什么必须启用 GPG 验证？
  #   --no-gpg-verify 会导致安装应用时报错：
  #   "无法从不信任的远程仓库提取"
  #   导入 GPG 公钥 → 启用签名验证 → 解决此问题
  #
  #   依赖关系：
  #   - 需要 flatpak-system-helper.service 运行
  #   - 需要网络连接（network-online.target）
  #
  #   StandardOutput/StandardError 设为 "null"：
  #   禁止命令输出到控制台 —— 避免 curl/flatpak 的输出在登录界面
  #   上显示杂乱文本，影响美观。
  # ============================================================================
  systemd.services.flatpak-configure-ustc = {
    description = "配置 Flathub 远程仓库为 USTC 镜像（含 GPG 验证）";
    wantedBy = [ "multi-user.target" ];
    after = [ "flatpak-system-helper.service" "network-online.target" ];
    wants = [ "flatpak-system-helper.service" "network-online.target" ];
    script = ''
      # 步骤 1：下载 Flathub 官方 GPG 公钥
      #   flatpak 使用 GPG 签名验证每个应用的完整性，
      #   没有此文件将无法验证应用包的来源可信性。
      ${pkgs.curl}/bin/curl -fLSs -o /tmp/flathub.gpg \
        https://flathub.org/repo/flathub.gpg 2>/dev/null

      # 步骤 2：添加名为 "flathub" 的远程仓库
      #   注意：flatpak 会在添加后自动将 URL 纠正为官方地址
      #   （dl.flathub.org），但这不影响后续步骤。
      ${pkgs.flatpak}/bin/flatpak remote-add \
        --gpg-import=/tmp/flathub.gpg \
        --if-not-exists --system flathub https://mirrors.ustc.edu.cn/flathub \
        >/dev/null 2>&1

      # 步骤 3：重新设置 URL 为 USTC 镜像
      #   覆盖 flatpak 的自动 URL 纠正行为，
      #   确保后续下载使用国内镜像加速。
      ${pkgs.flatpak}/bin/flatpak remote-modify \
        --url=https://mirrors.ustc.edu.cn/flathub flathub \
        >/dev/null 2>&1

      # 清理：删除临时 GPG 密钥文件
      rm -f /tmp/flathub.gpg
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StandardOutput = "null";                  # 禁止输出到控制台 —— 避免干扰 TUI 登录界面
      StandardError = "null";                   # 禁止错误输出到控制台
    };
  };
}
