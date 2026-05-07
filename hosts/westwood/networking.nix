{ config, lib, pkgs, ... }:

# ==============================================================================
# 网络配置
#
#   本文件管理 westwood 主机的网络相关设置，包括：
#   - 主机名（hostName）：标识主机在网络中的唯一名称
#   - NetworkManager：现代化的网络管理守护进程（支持 Wi-Fi/有线/移动网络）
#   - OpenSSH：安全远程登录服务，用于远程管理和文件传输
#
#   注意：NetworkManager 启用后，有线网络通常自动获取 IP（DHCP），
#   无线网络需通过 nmcli/nmtui/network-manager-applet 等工具手动连接。
#   如需静态 IP、网桥（bridge）或 VPN 等高级配置，请在 networking 中另行定义。
# ==============================================================================

{
  networking.hostName = "westwood";                    # 主机名 —— 局域网内标识此机器
  networking.networkmanager.enable = true;             # 启用 NetworkManager 管理网络连接

  # ============================================================================
  # SSH 远程访问
  #   sshd 服务监听默认端口 22，允许远程终端登录和文件传输（scp/sftp/rsync）
  #   默认允许所有本地用户使用密码登录。生产环境建议配置：
  #   - services.openssh.settings.PasswordAuthentication = false（仅密钥登录）
  #   - services.openssh.settings.Banner = "..."（登录横幅）
  #   - users.users.<name>.openssh.authorizedKeys.keys = [...]（授权密钥）
  # ============================================================================
  services.openssh.enable = true;
}
