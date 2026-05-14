{ config, pkgs, lib, ... }:

# ==============================================================================
# DMS 启动主题修复
#
#   Bug 描述：
#   DMS 设置自动深浅主题切换，但开机进入桌面时默认显示上次保存的主题
#   （通常是深色），需要手动点击 bar 后 DMS 才会"反应过来"，切换到当前
#   时间对应的深浅主题。
#
#   根因分析：
#   DMS 基于 Quickshell 构建。启动时读取 session.json 中上次保存的
#   isLightMode 状态，但自动深浅切换的定时器/评估逻辑在启动时未正确
#   触发。点击 bar 的 UI 事件触发了重新评估，才发现时间状态已变化。
#
#   修复方案：
#   Quickshell 默认捕获 SIGUSR1 作为 QML 重载信号。发送 SIGUSR1 给 DMS
#   进程会触发 QML 完全重载，重新评估所有绑定、Timer 和初始化逻辑，
#   包括自动深浅切换的时间检查。本服务在 DMS 启动后延迟 10 秒执行一次，
#   确保 DMS 已完全初始化。
#
#   副作用：
#   QML 重载期间 DMS bar 可能短暂闪烁（<1 秒），仅在开机时发生一次。
# ==============================================================================

{
  home.file."${config.home.homeDirectory}/.local/bin/dms-boot-theme-fix" = {
    executable = true;
    source = pkgs.writeShellScript "dms-boot-theme-fix" ''
      # 等待 DMS 完全启动并稳定（包括 matugen 首次渲染、portal 注册等）
      sleep 10

      # -----------------------------------------------------------------------
      # 获取 DMS 主进程 PID
      #   优先通过 systemd 查询 service 的 MainPID（最准确）
      #   如果 systemd 查询失败，回退到 pgrep 匹配 quickshell 进程
      # -----------------------------------------------------------------------
      DMS_PID=""
      for svc in dms.service dms-shell.service; do
        PID=$(systemctl --user show --property=MainPID --value "$svc" 2>/dev/null || true)
        if [ -n "$PID" ] && [ "$PID" != "0" ]; then
          DMS_PID="$PID"
          break
        fi
      done

      if [ -z "$DMS_PID" ] || [ "$DMS_PID" = "0" ]; then
        DMS_PID=$(pgrep -f "quickshell" | head -n1 || true)
      fi

      if [ -n "$DMS_PID" ] && [ "$DMS_PID" != "0" ]; then
        # Quickshell 捕获 SIGUSR1 → 重载所有 QML 文件
        # 这会重新触发 Component.onCompleted、Timer 初始化等逻辑，
        # 让 DMS 的自动深浅切换定时器立即根据当前时间重新评估。
        kill -USR1 "$DMS_PID" 2>/dev/null || true
      fi
    '';
  };

  systemd.user.services.dms-boot-theme-fix = {
    Unit = {
      Description = "Fix DMS startup theme by triggering QML reload";
      After = [ "dms.service" "graphical-session.target" ];
      Wants = [ "dms.service" ];
      # 限制启动次数：启动阶段仅运行一次，失败不重试
      StartLimitBurst = 3;
      StartLimitIntervalSec = 60;
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/bin/dms-boot-theme-fix";
      Restart = "no";
    };
    Install = { WantedBy = [ "default.target" ]; };
  };
}
