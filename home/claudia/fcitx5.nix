{ config, pkgs, lib, ... }:

# ==============================================================================
# Fcitx5 输入法配置 —— DMS 动态配色同步
#
#   本文件管理 Fcitx5 输入法框架的配色与 DMS（DankMaterialShell）的联动，
#   包括 DMS matugen 模板、自动同步脚本和 systemd 服务。
#
#   设计说明：
#   DMS 会根据壁纸生成动态主题色，但 fcitx5 的候选词窗口使用独立于
#   GTK/Qt 的 classicui 渲染，默认不会跟随 DMS 主题色。
#   本配置通过 DMS 模板 + systemd path 监听实现双向同步。
# ==============================================================================

{
  # ============================================================================
  # DMS 用户 matugen 模板 —— fcitx5 主题输出路径定义
  #
  #   fcitx5.toml 告诉 DMS 模板引擎处理 fcitx5-theme.conf
  #   fcitx5-theme.conf 使用 matugen 颜色变量（{{colors.*.hex}}）定义主题
  #   DMS 渲染后将 theme.conf 输出到 DATA_DIR/fcitx5/themes/dms/
  # ============================================================================

  # DMS 模板注册文件
  home.file.".config/dms/templates/fcitx5.toml" = {
    text = 
''
  [templates.dmsfcitx5]
  input_path = 'CONFIG_DIR/dms/templates/fcitx5-theme.conf'
  output_path = 'DATA_DIR/fcitx5/themes/dms/theme.conf'
''
    ;
    force = true;
  };

  # DMS matugen 模板 —— fcitx5 候选词窗口主题
  home.file.".config/dms/templates/fcitx5-theme.conf" = {
    text = 
''
  [Metadata]
  Name=DMS Dynamic
  Version=1
  Author=DankMaterialShell
  Description=Dynamic DMS theme generated with Matugen
  ScaleWithDPI=True

  [InputPanel]
  NormalColor={{colors.on_surface.default.hex}}
  HighlightCandidateColor={{colors.on_primary.default.hex}}
  HighlightColor={{colors.on_primary.default.hex}}
  HighlightBackgroundColor={{colors.primary.default.hex}}
  PageButtonAlignment=Last Candidate

  [InputPanel/TextMargin]
  Left=5
  Right=5
  Top=5
  Bottom=5

  [InputPanel/ContentMargin]
  Left=2
  Right=2
  Top=2
  Bottom=2

  [InputPanel/Background]
  Color={{colors.surface_container_low.default.hex}}
  BorderColor={{colors.outline_variant.default.hex}}
  BorderWidth=2

  [InputPanel/Background/Margin]
  Left=2
  Right=2
  Top=2
  Bottom=2

  [InputPanel/Highlight]
  Color={{colors.primary.default.hex}}

  [InputPanel/Highlight/Margin]
  Left=5
  Right=5
  Top=5
  Bottom=5

  [Menu]
  NormalColor={{colors.on_surface.default.hex}}
  HighlightCandidateColor={{colors.on_primary_container.default.hex}}

  [Menu/Background]
  Color={{colors.surface_container_low.default.hex}}
  BorderColor={{colors.outline_variant.default.hex}}
  BorderWidth=2

  [Menu/Background/Margin]
  Left=2
  Right=2
  Top=2
  Bottom=2

  [Menu/ContentMargin]
  Left=2
  Right=2
  Top=2
  Bottom=2

  [Menu/Highlight]
  Color={{colors.primary.default.hex}}

  [Menu/Highlight/Margin]
  Left=5
  Right=5
  Top=5
  Bottom=5

  [Menu/Separator]
  Color={{colors.outline_variant.default.hex}}

  [Menu/TextMargin]
  Left=5
  Right=5
  Top=5
  Bottom=5
''
    ;
    force = true;
  };

  # ============================================================================
  # DMS → fcitx5 配色自动同步脚本
  #
  #   当 DMS 更新配色文件时，自动重写 fcitx5 的 theme.conf 并通知
  #   fcitx5 重新加载，保持输入法配色始终匹配当前壁纸提取的 DMS 动态配色。
  # ============================================================================

  home.file."${config.home.homeDirectory}/.local/bin/dms-fcitx5-sync" = {
    executable = true;
    source = pkgs.writeShellScript "dms-fcitx5-sync" ''
      DMS_CLR="${config.home.homeDirectory}/.cache/DankMaterialShell/dms-colors.json"
      DMS_SES="${config.home.homeDirectory}/.local/state/DankMaterialShell/session.json"
      OUT_DIR="${config.home.homeDirectory}/.local/share/fcitx5/themes/dms"
      OUT="$OUT_DIR/theme.conf"

      [[ -f "$DMS_CLR" && -f "$DMS_SES" ]] || exit 0

      # 等待配色文件稳定：DMS 在壁纸切换时可能连续多次写入中间配色
      CLR_MTIME=$(stat -c "%Y" "$DMS_CLR" 2>/dev/null || echo 0)
      sleep 1.0
      NEW_MTIME=$(stat -c "%Y" "$DMS_CLR" 2>/dev/null || echo 0)
      [ "$CLR_MTIME" = "$NEW_MTIME" ] || exit 0

      IS_LIGHT=$(${pkgs.jq}/bin/jq -r '.isLightMode' < "$DMS_SES")
      SCHEME=$([ "$IS_LIGHT" = "true" ] && echo "light" || echo "dark")
      c() { ${pkgs.jq}/bin/jq -r ".colors.$SCHEME.$1 // \"#000000\"" < "$DMS_CLR"; }

      OS=$(c on_surface); OP=$(c on_primary); PR=$(c primary)
      PC=$(c primary_container); OPC=$(c on_primary_container)
      SCL=$(c surface_container_low); OV=$(c outline_variant)

      mkdir -p "$OUT_DIR"
      exec 9>"$OUT_DIR/sync.lock"
      flock -n 9 || exit 0

      cat > "$OUT" << FCITX5_THEME_EOF
      [Metadata]
      Name=DMS Dynamic ($SCHEME)
      Version=1
      Author=DankMaterialShell (auto-sync)
      Description=DMS dynamic theme - $SCHEME scheme
      ScaleWithDPI=True

      [InputPanel]
      NormalColor=$OS
      HighlightCandidateColor=$OP
      HighlightColor=$OP
      HighlightBackgroundColor=$PR
      PageButtonAlignment=Last Candidate

      [InputPanel/TextMargin]
      Left=5
      Right=5
      Top=5
      Bottom=5

      [InputPanel/ContentMargin]
      Left=2
      Right=2
      Top=2
      Bottom=2

      [InputPanel/Background]
      Color=$SCL
      BorderColor=$OV
      BorderWidth=2

      [InputPanel/Background/Margin]
      Left=2
      Right=2
      Top=2
      Bottom=2

      [InputPanel/Highlight]
      Color=$PR

      [InputPanel/Highlight/Margin]
      Left=5
      Right=5
      Top=5
      Bottom=5

      [Menu]
      NormalColor=$OS
      HighlightCandidateColor=$OPC

      [Menu/Background]
      Color=$SCL
      BorderColor=$OV
      BorderWidth=2

      [Menu/Background/Margin]
      Left=2
      Right=2
      Top=2
      Bottom=2

      [Menu/ContentMargin]
      Left=2
      Right=2
      Top=2
      Bottom=2

      [Menu/Highlight]
      Color=$PR

      [Menu/Highlight/Margin]
      Left=5
      Right=5
      Top=5
      Bottom=5

      [Menu/Separator]
      Color=$OV

      [Menu/TextMargin]
      Left=5
      Right=5
      Top=5
      Bottom=5
      FCITX5_THEME_EOF

      # 方式1: touch classicui.conf —— 触发 fcitx5 守护进程的配置文件监听器，自动重载配置和主题
      touch "${config.home.homeDirectory}/.config/fcitx5/conf/classicui.conf"
      # 方式2: SIGUSR1 —— 后备机制（守护进程收到后重建全部配置）
      ${pkgs.procps}/bin/pkill -x -SIGUSR1 fcitx5 2>/dev/null || true
    '';
  };

  systemd.user.services.dms-fcitx5-sync = {
    Unit = { Description = "Sync DMS wallpaper colors to fcitx5 theme"; };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/bin/dms-fcitx5-sync";
      Restart = "no";
      StartLimitBurst = 30;
    };
    Install = { WantedBy = [ "default.target" ]; };
  };

  systemd.user.paths.dms-fcitx5-sync = {
    Unit = { Description = "Watch DMS colors and sync to fcitx5 theme"; };
    Path = {
      PathChanged = [
        "%h/.cache/DankMaterialShell/dms-colors.json"
        "%h/.local/state/DankMaterialShell/dms-colors.json"
        "%h/.local/state/DankMaterialShell/session.json"
      ];
    };
    Install = { WantedBy = [ "default.target" ]; };
  };

  # ============================================================================
  # fcitx5 classicui 主题 —— 锁定为 DMS 动态配色
  # ============================================================================
  home.activation.lockFcitx5ClassicuiTheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
    CFG="/home/claudia/.config/fcitx5/conf/classicui.conf"
    mkdir -p "$(dirname "$CFG")"
    ${pkgs.e2fsprogs}/bin/chattr -i "$CFG" 2>/dev/null || true
    cat > "$CFG" <<- 'THEMEEOF'
# 注意：首行 Theme=dms 必须无 section 头，因为 fcitx5-gtk 的 ClassicUIConfig
# 将此文件内容包裹在 [Group] 下解析，若首行是 [Config]，Theme 会落在
# [Config] 段而非 [Group]，导致 GTK IM 模块主题回退为 default。

# 下面的 [Config] 段供 fcitx5-daemon 的 classicui 插件使用（标准 fcitx5 配置格式）。
# 两个 Theme 指向同一个 dms 主题，确保终端和 GTK 应用配色一致。
Theme=dms

[Config]
# DMS 动态主题（由 DMS matugen 模板生成）
# 路径: ~/.local/share/fcitx5/themes/dms/theme.conf
Theme=dms
THEMEEOF
    ${pkgs.e2fsprogs}/bin/chattr +i "$CFG" 2>/dev/null || true
  '';

  # ============================================================================
  # fcitx5 禁用冲突的 UI 插件 —— 确保所有输入法前端都使用 classicui 渲染
  # ============================================================================
  home.activation.disableFcitx5ConflictUI = lib.hm.dag.entryAfter ["writeBoundary"] ''
    FCITX_CFG="/home/claudia/.config/fcitx5/config"
    mkdir -p "$(dirname "$FCITX_CFG")"

    if [ ! -f "$FCITX_CFG" ]; then
      cat > "$FCITX_CFG" <<- 'FCITXEOF'
[Behavior]
DisabledAddons=kimpanel,virtualkeyboard
FCITXEOF
    else
      if grep -q "^\[Behavior\]" "$FCITX_CFG"; then
        if grep -q "^DisabledAddons=" "$FCITX_CFG"; then
          ${pkgs.gawk}/bin/awk -i inplace '
            BEGIN { FS=OFS="=" }
            /^DisabledAddons=/ {
              split($2, arr, ",")
              has_kim=0; has_vk=0
              for (i in arr) {
                gsub(/^[ \t]+|[ \t]+$/, "", arr[i])
                if (arr[i]=="kimpanel") has_kim=1
                if (arr[i]=="virtualkeyboard") has_vk=1
              }
              new_list=$2
              if (!has_kim) new_list = (new_list ? new_list "," : "") "kimpanel"
              if (!has_vk) new_list = (new_list ? new_list "," : "") "virtualkeyboard"
              gsub(/^,/, "", new_list)
              $0 = "DisabledAddons=" new_list
            }
            { print }
          ' "$FCITX_CFG"
        else
          ${pkgs.gawk}/bin/awk -i inplace '
            /^\[Behavior\]/ { print; print "DisabledAddons=kimpanel,virtualkeyboard"; next }
            { print }
          ' "$FCITX_CFG"
        fi
      else
        cat >> "$FCITX_CFG" <<- 'FCITXEOF'

[Behavior]
DisabledAddons=kimpanel,virtualkeyboard
FCITXEOF
      fi
    fi
  '';
}
