{ config, pkgs, ... }:

# ==============================================================================
# Fuzzel 应用启动器 —— DMS 动态配色同步
#
#   本文件管理 Fuzzel 应用启动器的 DMS 动态配色同步。
#
#   设计说明：
#   DMS 会根据壁纸生成动态主题色，但 fuzzel 使用独立的配置格式，
#   默认不会跟随 DMS 主题色变化。
#
#   本配置通过 systemd path 监听 + 同步脚本实现 fuzzel 配色与 DMS 同步。
#   当 DMS 的配色文件变化时（切换壁纸或深浅主题），自动重新生成
#   fuzzel.ini。由于 fuzzel 每次启动时重新读取配置，无需发送重载信号。
#
#   注意：不使用 DMS matugen 模板方式（{{colors.*.default.hex}}），
#   因为 dms-colors.json 的 colors 对象只有 dark/light 分支，没有
#   default 分支，模板无法正确渲染。改为脚本直接读取 JSON 并选择
#   正确的配色方案。
#
#   配色映射关系（Material Design → fuzzel）：
#     background      = surface_container_low    # 窗口背景色
#     text            = on_surface               # 未选中条目文字
#     message         = on_surface_variant       # 消息文字
#     prompt          = primary                  # 提示符
#     placeholder     = outline                  # 占位符文字
#     input           = on_surface               # 输入文字
#     match           = primary                  # 匹配高亮
#     selection       = primary_container        # 选中条目背景
#     selection-text  = on_primary_container     # 选中条目文字
#     selection-match = primary                  # 选中条目的匹配高亮
#     counter         = on_surface_variant       # 计数统计
#     border          = outline_variant          # 边框色
# ==============================================================================

{
  # ============================================================================
  # DMS → fuzzel 配色自动同步脚本
  # ============================================================================

  home.file."${config.home.homeDirectory}/.local/bin/dms-fuzzel-sync" = {
    executable = true;
    source = pkgs.writeShellScript "dms-fuzzel-sync" ''
      DMS_CLR="${config.home.homeDirectory}/.cache/DankMaterialShell/dms-colors.json"
      DMS_SES="${config.home.homeDirectory}/.local/state/DankMaterialShell/session.json"
      OUT_DIR="${config.home.homeDirectory}/.config/fuzzel"
      OUT="$OUT_DIR/fuzzel.ini"

      [[ -f "$DMS_CLR" && -f "$DMS_SES" ]] || exit 0

      IS_LIGHT=$(${pkgs.jq}/bin/jq -r '.isLightMode' < "$DMS_SES")
      SCHEME=$([ "$IS_LIGHT" = "true" ] && echo "light" || echo "dark")
      c() { ${pkgs.jq}/bin/jq -r ".colors.$SCHEME.$1 // \"#000000\"" < "$DMS_CLR"; }

      # 将 #RRGGBB 转为 RRGGBBFF（fuzzel 使用 8 位 RGBA 格式，不含 # 前缀）
      cf() { printf '%sff\n' "$(c "$1" | sed 's/^#//')"; }

      mkdir -p "$OUT_DIR"
      exec 9>"$OUT_DIR/sync.lock"
      flock -n 9 || exit 0

      cat > "$OUT" << FCITX5_THEME_EOF
      [main]
      font=JetBrainsMono Nerd Font:size=14
      prompt=>
      lines=12
      width=50
      horizontal-pad=30
      vertical-pad=12
      inner-pad=6
      icon-theme=Adwaita
      layer=overlay
      anchor=center

      [border]
      width=2
      radius=12

      [colors]
      background=$(cf surface_container_low)
      text=$(cf on_surface)
      message=$(cf on_surface_variant)
      prompt=$(cf primary)
      placeholder=$(cf outline)
      input=$(cf on_surface)
      match=$(cf primary)
      selection=$(cf primary_container)
      selection-text=$(cf on_primary_container)
      selection-match=$(cf primary)
      counter=$(cf on_surface_variant)
      border=$(cf outline_variant)
      XXXX
    '';
  };

  systemd.user.services.dms-fuzzel-sync = {
    Unit = { Description = "Sync DMS wallpaper colors to fuzzel theme"; };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/bin/dms-fuzzel-sync";
      StartLimitBurst = 30;
      StartLimitIntervalSec = 30;
    };
  };

  systemd.user.paths.dms-fuzzel-sync = {
    Unit = { Description = "Watch DMS colors and sync to fuzzel theme"; };
    Path = {
      PathChanged = [
        "%h/.cache/DankMaterialShell/dms-colors.json"
        "%h/.local/state/DankMaterialShell/dms-colors.json"
        "%h/.local/state/DankMaterialShell/session.json"
      ];
    };
    Install = { WantedBy = [ "default.target" ]; };
  };
}
