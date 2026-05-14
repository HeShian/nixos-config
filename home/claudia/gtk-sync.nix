{ config, pkgs, ... }:

# ==============================================================================
# DMS → GTK 深浅主题同步 & Remmina 包装脚本
#
#   本文件管理 DMS（DankMaterialShell）与 GTK 应用深浅主题的同步，
#   以及 Remmina 远程桌面客户端的主题适配。
#
#   设计说明：
#   DMS 会在切换壁纸或深浅主题时更新配色，但 GTK 应用的 settings.ini
#   默认不会跟随 DMS 的变化。这导致 Thunar、Remmina、virt-manager 等应用
#   在 DMS 切换深浅主题时颜色不跟随变化。
#
#   GTK 深浅主题控制层级（优先级从高到低）：
#   A. gsettings/dconf color-scheme（GTK4/libadwaita 应用）
#   B. settings.ini（GTK3 应用，如 Remmina）
#   C. xfconf（Xfce 应用，如 Thunar）
# ==============================================================================

{
  # ============================================================================
  # DMS → GTK 配色自动同步脚本
  #
  #   读取 DMS session.json 的 isLightMode，同步以下设置：
  #   1. dconf color-scheme（GTK4/libadwaita 实时切换）
  #   2. gtk-3.0/4.0 settings.ini（GTK3 新启动应用）
  #   3. xfconf（Thunar 等 Xfce 应用）
  #   4. Remmina 自身 dark_theme 配置
  # ============================================================================

  home.file."${config.home.homeDirectory}/.local/bin/dms-gtk-sync" = {
    executable = true;
    source = pkgs.writeShellScript "dms-gtk-sync" ''
      DMS_SES="${config.home.homeDirectory}/.local/state/DankMaterialShell/session.json"
      [[ -f "$DMS_SES" ]] || exit 0

      IS_LIGHT=$(${pkgs.jq}/bin/jq -r '.isLightMode' < "$DMS_SES")
      if [ "$IS_LIGHT" = "true" ]; then
        PREFER_DARK=0
        COLOR_SCHEME="default"
        XFCE_THEME="Adwaita"
      else
        PREFER_DARK=1
        COLOR_SCHEME="prefer-dark"
        XFCE_THEME="Adwaita-dark"
      fi

      # 1. dconf → GTK4/libadwaita 实时 color-scheme
      ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'$COLOR_SCHEME'" 2>/dev/null || true
      ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/gtk-theme "'Adwaita'" 2>/dev/null || true

      # 2. GTK3/GTK4 settings.ini
      write_gtk_ini() {
        local DIR="$1"
        local INI="$DIR/settings.ini"
        mkdir -p "$DIR"
        if [ -f "$INI" ]; then
          ${pkgs.gawk}/bin/awk \
            -v dark="$PREFER_DARK" '
            /^gtk-application-prefer-dark-theme=/ { found_dk=1; print "gtk-application-prefer-dark-theme=" dark; next }
            /^gtk-theme-name=/             { found_th=1; print "gtk-theme-name=Adwaita"; next }
            { print }
            END {
              if (!found_th) print "gtk-theme-name=Adwaita"
              if (!found_dk) print "gtk-application-prefer-dark-theme=" dark
            }
          ' "$INI" > "$INI.tmp" && mv "$INI.tmp" "$INI"
        else
          cat > "$INI" << GTK_INI
      [Settings]
      gtk-theme-name=Adwaita
      gtk-application-prefer-dark-theme=$PREFER_DARK
      gtk-icon-theme-name=Adwaita
      GTK_INI
        fi
      }

      exec 9>"${config.home.homeDirectory}/.config/gtk-3.0/sync.lock"
      flock -n 9 || exit 0
      write_gtk_ini "${config.home.homeDirectory}/.config/gtk-3.0"
      write_gtk_ini "${config.home.homeDirectory}/.config/gtk-4.0"

      # 3. Remmina 主题配置
      REMMINA_PREF="${config.home.homeDirectory}/.config/remmina/remmina.pref"
      mkdir -p "$(dirname "$REMMINA_PREF")"
      if [ -f "$REMMINA_PREF" ]; then
        ${pkgs.gawk}/bin/awk \
          -v dark="$PREFER_DARK" '
          /^dark_theme=/ { found=1; print "dark_theme=" (dark ? "true" : "false"); next }
          { print }
          END { if (!found) print "dark_theme=" (dark ? "true" : "false") }
        ' "$REMMINA_PREF" > "$REMMINA_PREF.tmp" && mv "$REMMINA_PREF.tmp" "$REMMINA_PREF"
      else
        echo "dark_theme=$([ "$PREFER_DARK" = "1" ] && echo "true" || echo "false")" > "$REMMINA_PREF"
      fi

      # 4. xfconf → Thunar 等 Xfce 应用深浅主题
      ${pkgs.xfconf}/bin/xfconf-query -c xsettings -p /Net/ThemeName \
        -n -t string -s "$XFCE_THEME" 2>/dev/null || true
      ${pkgs.xfconf}/bin/xfconf-query -c xsettings -p /Net/IconThemeName \
        -n -t string -s "Adwaita" 2>/dev/null || true
    '';
  };

  systemd.user.services.dms-gtk-sync = {
    Unit = {
      Description = "Sync DMS wallpaper colors to GTK theme";
      After = [ "dms.service" ];
      Wants = [ "dms.service" ];
      StartLimitBurst = 30;
      StartLimitIntervalSec = 60;
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/bin/dms-gtk-sync";
      ExecStartPost = [
        "${pkgs.coreutils}/bin/sleep 4"
        "${config.home.homeDirectory}/.local/bin/dms-gtk-sync"
      ];
      Restart = "no";
    };
    Install = { WantedBy = [ "default.target" ]; };
  };

  systemd.user.paths.dms-gtk-sync = {
    Unit = { Description = "Watch DMS colors and sync to GTK theme"; };
    Path = {
      PathChanged = [
        "%h/.local/state/DankMaterialShell/session.json"
      ];
    };
    Install = { WantedBy = [ "default.target" ]; };
  };

  # ============================================================================
  # Remmina 启动包装脚本
  #
  #   Remmina 不响应 settings.ini 的 gtk-application-prefer-dark-theme 标志，
  #   也不响应 dconf color-scheme 变化。但 Remmina 会读取 GTK_THEME 环境变量
  #   （最高优先级）。此包装脚本在启动 Remmina 时根据 DMS 当前模式动态设置
  #   GTK_THEME 环境变量，实现深浅主题跟随。
  # ============================================================================

  home.file."${config.home.homeDirectory}/.local/bin/remmina" = {
    executable = true;
    source = pkgs.writeShellScript "remmina-wrapper" ''
      DMS_SES="${config.home.homeDirectory}/.local/state/DankMaterialShell/session.json"
      if [ -f "$DMS_SES" ]; then
        IS_LIGHT=$(${pkgs.jq}/bin/jq -r '.isLightMode' < "$DMS_SES")
        if [ "$IS_LIGHT" = "true" ]; then
          export GTK_THEME="Adwaita"
        else
          export GTK_THEME="Adwaita:dark"
        fi
      fi
      # 同步写入 Remmina 自身 dark_theme 配置
      REMMINA_PREF="${config.home.homeDirectory}/.config/remmina/remmina.pref"
      mkdir -p "${config.home.homeDirectory}/.config/remmina"
      DARK_VAL=$([ "$IS_LIGHT" = "true" ] && echo "false" || echo "true")
      if [ -f "$REMMINA_PREF" ]; then
        ${pkgs.gawk}/bin/awk \
          -v dark="$DARK_VAL" '
          /^dark_theme=/ { found=1; print "dark_theme=" dark; next }
          { print }
          END { if (!found) print "dark_theme=" dark }
        ' "$REMMINA_PREF" > "$REMMINA_PREF.tmp" && mv "$REMMINA_PREF.tmp" "$REMMINA_PREF"
      else
        echo "dark_theme=$DARK_VAL" > "$REMMINA_PREF"
      fi
      exec ${pkgs.remmina}/bin/remmina "$@"
    '';
  };

  # 覆盖 Remmina 的 .desktop 文件，使 fuzzel/应用启动器调用包装脚本
  xdg.desktopEntries."org.remmina.Remmina" = {
    name = "Remmina";
    genericName = "Remote Desktop Client";
    exec = "${config.home.homeDirectory}/.local/bin/remmina %U";
    categories = [ "Network" "GTK" ];
    mimeType = [ "x-scheme-handler/remmina" ];
  };
}
