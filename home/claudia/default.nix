{ config, pkgs, inputs, lib, ... }:

# ==============================================================================
# Home Manager —— 用户：claudia
#   本文件是用户级配置的总入口，通过 imports 引入各程序子模块。
#   所有配置只影响当前用户，不会污染系统全局。
# ==============================================================================

{
  # 导入子模块 —— 按程序/功能拆分，方便维护
  imports = [
    ./shell.nix       # Shell 环境（bash / zsh / fish）
    ./git.nix         # Git 版本控制配置
    ./nvim.nix        # Nixvim（Neovim 编辑器配置）
    ./niri.nix        # niri Wayland 合成器配置
    ./xdg.nix         # XDG 基础配置（mimeapps、user-dirs、Xresources）
  ];

  # ============================================================================
  # 用户基本信息
  # ============================================================================
  home.username = "claudia";
  home.homeDirectory = "/home/claudia";

  # ============================================================================
  # Home Manager 版本（用于向后兼容判定，不要随意修改）
  # ============================================================================
  home.stateVersion = "25.11";

  # ============================================================================
  # 让 Home Manager 管理 Shell 的初始化文件（如 .bashrc、.zshrc）
  #   启用后，HM 会接管 ~/.bashrc 等文件的管理，手动修改将被覆盖
  # ============================================================================

  # ============================================================================
  # 用户级软件包（仅当前用户可用，不需要 sudo 安装）
  # ============================================================================
  # ============================================================================
  # ============================================================================
  # 将 ~/.local/bin 加入 PATH，确保 remmina 包装脚本优先于系统包
  # ============================================================================
  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

  # ============================================================================
  # Fcitx5 输入法主题 —— DMS 动态配色适配
  #
  #   DMS（DankMaterialShell）会根据壁纸生成动态主题色，但 fcitx5 的候选词窗口
  #   使用独立于 GTK/Qt 的 classicui 渲染，默认不会跟随 DMS 主题色。
  #
  #   本配置通过 DMS 的用户 matugen 模板系统（runUserMatugenTemplates 已启用），
  #   在 DMS 切换壁纸/主题时自动生成 fcitx5 的 theme.conf，使输入法候选框
  #   在所有应用中（terminal、Firefox、Electron 等）都使用一致的 DMS 配色。
  #
  #   工作原理：
  #     1. fcitx5.toml 告诉 DMS 模板引擎处理 fcitx5-theme.conf
  #     2. fcitx5-theme.conf 使用 matugen 颜色变量（{{colors.*.hex}}）定义主题
  #     3. DMS 渲染后将 theme.conf 输出到 DATA_DIR/fcitx5/themes/dms/
  #     4. classicui.conf 让 fcitx5 使用 "dms" 主题
  # ============================================================================

  # DMS 用户 matugen 模板配置 —— 定义 fcitx5 主题的输出路径
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

  # DMS → fcitx5 配色自动同步
  #
  #   fcitx5 自动跟随 DMS 壁纸配色的同步脚本 + systemd path 单元。
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
      sleep 0.3
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
      XXXX

      kill -SIGUSR1 $(${pkgs.procps}/bin/pgrep -x fcitx5) 2>/dev/null || true
    '';
  };

  systemd.user.services.dms-fcitx5-sync = {
    Unit = { Description = "Sync DMS wallpaper colors to fcitx5 theme"; };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/bin/dms-fcitx5-sync";
      Restart = "no";
      StartLimitBurst = 30;
      StartLimitIntervalSec = 60;
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
  #   写入 classicui.conf 后将文件设为不可变（chattr +i），防止 fcitx5
  #   运行时配置工具覆盖 Theme 设置。重建时先移除不可变标记再写入。
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
  #
  #   禁用 KDE Input Method Panel 和 DBus Virtual Keyboard，
  #   强制所有前端（wayland、dbus、xcb）统一使用 Classic User Interface。
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


  # ============================================================================
  # Fuzzel 应用启动器 —— DMS 动态配色适配
  #
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
  # ============================================================================
  #
  # 配色映射关系（Material Design → fuzzel）：
  #   background      = surface_container_low    # 窗口背景色
  #   text            = on_surface               # 未选中条目文字
  #   message         = on_surface_variant       # 消息文字
  #   prompt          = primary                  # 提示符
  #   placeholder     = outline                  # 占位符文字
  #   input           = on_surface               # 输入文字
  #   match           = primary                  # 匹配高亮
  #   selection       = primary_container        # 选中条目背景
  #   selection-text  = on_primary_container     # 选中条目文字
  #   selection-match = primary                  # 选中条目的匹配高亮
  #   counter         = on_surface_variant       # 计数统计
  #   border          = outline_variant          # 边框色
  # ============================================================================

  # DMS → fuzzel 配色自动同步
  #
  #   systemd path 监听 dms-colors.json 和 session.json 的变化，
  #   触发同步脚本重新生成 ~/.config/fuzzel/fuzzel.ini。
  #   自动识别深浅主题（isLightMode），将 Material Color 色值转为
  #   fuzzel 的 RRGGBBFF RGBA 格式。
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

  # ============================================================================
  # DMS → GTK 深浅主题同步
  #
  #   DMS（DankMaterialShell）会在切换壁纸或深浅主题时更新配色，
  #   但 GTK 应用的 settings.ini 默认不会跟随 DMS 的变化。这导致
  #   Thunar、Remmina、virt-manager 等应用在 DMS 切换深浅主题时
  #   颜色不跟随变化。
  #
  #   DMS 已通过 dank-colors.css 提供了 GTK CSS 配色（定义 @define-color
  #   变量覆盖 Adwaita 的默认颜色），但这个 CSS 只控制颜色值，不控制
  #   深浅模式开关。GTK 应用控制深浅模式有以下几个层级，优先级从高到低：
  #
  #   A. gsettings/dconf color-scheme（GTK4 / libadwaita 应用）
  #      → 通过 dconf write 写入 org.gnome.desktop.interface color-scheme
  #      → 对 virt-manager、GNOME 应用等 GTK4 应用实时生效
  #      → 需要 gsettings-desktop-schemas 包提供 schema
  #
  #   B. settings.ini（GTK3 应用，如 Remmina）
  #      → gtk-theme-name=Adwaita + gtk-application-prefer-dark-theme
  #      → 新启动的 GTK3 应用自动使用深色/浅色主题
  #
  #   C. xfconf（Xfce 应用，如 Thunar）
  #      → 通过 xfconf-query 设置 /Net/ThemeName
  #      → Thunar 读取此设置确定主题
  #
  #   本配置通过 systemd path 监听 DMS 状态变化，在 DMS 切换深浅主题时
  #   同时更新以上三个层级的设置，确保所有 GTK 应用跟随 DMS 主题。
  #
  #   工作原理：
  #     1. systemd path 监听 session.json（含 isLightMode 标志）
  #     2. 触发同步脚本，检测当前 isLightMode
  #     3. dconf write → GTK4/libadwaita 应用实时切换
  #     4. 写入 settings.ini → GTK3 新启动应用使用正确主题
  #     5. xfconf-query → Thunar 等 Xfce 应用切换
  # ============================================================================

  # DMS → GTK 配色自动同步脚本
  #
  #   读取 DMS session.json 的 isLightMode，同步以下设置：
  #   1. dconf color-scheme（GTK4/libadwaita 实时切换）
  #   2. gtk-3.0/4.0 settings.ini（GTK3 新启动应用）
  #   3. xfconf（Thunar 等 Xfce 应用）
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

      # ============================================================================
      # 1. dconf → GTK4/libadwaita 实时 color-scheme
      #    virt-manager 等 GTK4 应用监听此 gsettings 信号，无需重启自动切换。
      #    同时设置 gtk-theme 为 Adwaita，防止 DMS 的 portal 同步写入
      #    未安装的 adw-gtk3-dark 主题导致 GTK 回退到浅色主题。
      # ============================================================================
      ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'$COLOR_SCHEME'" 2>/dev/null || true
      ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/gtk-theme "'Adwaita'" 2>/dev/null || true

      # ============================================================================
      # 2. GTK3/GTK4 settings.ini
      #    官方 GTK3 文档指定深色模式的正确方式：
      #      gtk-application-prefer-dark-theme=1  + gtk-theme-name=Adwaita
      #    不使用 :dark 变体名称（在部分 GTK3 版本中无效）。
      # ============================================================================
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

      # ============================================================================
      # 3. Remmina 主题配置 ← 独立设置，不走 GTK
      #    Remmina 使用自己的 dark_theme 配置项（~/.config/remmina/remmina.pref），
      #    此设置独立于 GTK 的 settings.ini 和 dconf，必须单独管理。
      # ============================================================================
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

      # ============================================================================
      # 4. xfconf → Thunar 等 Xfce 应用深浅主题
      #    Thunar 通过 Xfce 的 xsettings 服务读取主题名称。xfconf-query
      #    通过 D-Bus 写入 xfconf 数据库，需 xfconfd 运行中。
      #    -n 参数在属性不存在时创建，-t string 指定类型为字符串。
      #    如果 xfconfd 未运行则静默跳过。
      # ============================================================================
      ${pkgs.xfconf}/bin/xfconf-query -c xsettings -p /Net/ThemeName \
        -n -t string -s "$XFCE_THEME" 2>/dev/null || true
      ${pkgs.xfconf}/bin/xfconf-query -c xsettings -p /Net/IconThemeName \
        -n -t string -s "Adwaita" 2>/dev/null || true
    '';
  };

  systemd.user.services.dms-gtk-sync = {
    Unit = {
      Description = "Sync DMS wallpaper colors to GTK theme";
      After = [ "dms.service" ];              # DMS 启动完成后才执行初始同步
      Wants = [ "dms.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/bin/dms-gtk-sync";
      # DMS 启动时可能通过 portal 同步覆盖我们刚写入的 dconf 值，
      # 延迟 4 秒后重跑一次确保最终状态正确。
      ExecStartPost = [
        "${pkgs.coreutils}/bin/sleep 4"
        "${config.home.homeDirectory}/.local/bin/dms-gtk-sync"
      ];
      Restart = "no";
      StartLimitBurst = 30;
      StartLimitIntervalSec = 60;
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
  #
  #   GTK_THEME 仅在进程启动时读取，不会固定系统级环境变量，不影响其他应用。
  #   切换主题后需关闭 Remmina 重启才能生效（GTK3 限制）。
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

  home.packages = with pkgs; [
    kitty
    fuzzel
    swaylock
    brightnessctl  # 屏幕亮度控制
    eza           # 彩色 ls（带图标）
    bat           # 彩色 cat（语法高亮）
    btop          # 系统监控
    fastfetch     # 系统信息显示
    satty         # 截图标注编辑
    grim          # Wayland 截图
    slurp         # 区域选择
    cliphist      # 剪贴板历史
    wl-clipboard   # wl-copy/wl-paste
    xfce4-exo      # exo-open（Thunar 右键打开终端依赖）

    # --- 通讯社交 ---
    wechat                     # 微信
    qq                         # QQ
    wemeet                     # 腾讯会议
    telegram-desktop           # Telegram
    discord                    # Discord

    # --- 下载工具 ---
    gopeed                     # 现代下载管理器
    qbittorrent                # BitTorrent 客户端

    # --- 远程桌面 & 文件传输 ---
    remmina                    # 远程桌面客户端（RDP/VNC/SSH）
    localsend                  # 跨平台文件传输（AirDrop 替代）

    # --- 音乐 ---
    go-musicfox                # Musicfox —— 终端网易云音乐

    # --- 游戏 ---
    lutris                     # 游戏平台（WINE 管理器）
    heroic                     # Heroic Games Launcher（Epic/GOG/Amazon）

    # --- 工具 ---
    bilibili-tui              # Bilibili TUI 终端客户端
    mpv                       # 视频播放器（bilibili-tui 依赖）
    yt-dlp                    # 视频流提取（bilibili-tui 依赖）
    virt-manager              # 虚拟机管理器（KVM 前端）
    xwayland-satellite         # XWayland 兼容层（niri 需要）
    mpvScripts.bdanmaku       # Bilibili 弹幕 mpv 插件
    biliass                   # Bilibili 弹幕转 ASS 字幕
  ];

  # ============================================================================
  # MPV 配置（参考 emoeem/mpv 项目适配）
  # ============================================================================
  home.file.".config/mpv/mpv.conf" = {
    text = ''
      # ======================================================================
      # 视频输出
      # ======================================================================
      vo=gpu-next
      hwdec=nvdec-copy                    # NVIDIA NVDEC 硬解（copy 模式兼容 Wayland）
      hwdec-codecs=all                    # 全部编码格式尝试硬解
      gpu-context=wayland                 # Wayland 输出
      # gpu-api=vulkan                    # Vulkan 渲染（如支持可启用）

      # ======================================================================
      # 高质量缩放（GPU 内置算法）
      # ======================================================================
      profile=gpu-hq
      scale=ewa_lanczossharp
      cscale=bilinear
      dscale=catmull_rom
      scale-antiring=0.5
      dscale-antiring=0.5
      linear-upscaling=no
      sigmoid-upscaling=yes
      correct-downscaling=yes
      linear-downscaling=no

      # ======================================================================
      # 去色带
      # ======================================================================
      deband
      deband-iterations=1
      deband-threshold=48
      deband-range=16
      deband-grain=16

      # ======================================================================
      # HDR 色彩管理
      # ======================================================================
      icc-profile-auto
      icc-intent=0
      icc-force-contrast=1000
      icc-3dlut-size=128x128x128
      icc-cache-dir="~~/cache/icc_cache"

      # HDR 色调映射
      hdr-contrast-recovery=0.30
      hdr-compute-peak=auto
      tone-mapping=auto

      # ======================================================================
      # 视频同步
      # ======================================================================
      video-sync=display-resample

      # ======================================================================
      # 音频
      # ======================================================================
      ao=pipewire                         # PipeWire 音频后端
      audio-format=float                  # 32位浮点音频
      audio-channels=auto
      audio-file-auto=fuzzy
      volume-max=200
      alang=japanese,jpn,jap,ja,jp,english,eng,en
      replaygain=album

      # ======================================================================
      # OSD
      # ======================================================================
      osd-font="Noto Sans CJK SC;Noto Color Emoji"
      osd-font-size=24
      osd-color="#FFFFFF"
      osd-duration=2000
      osd-on-seek=msg-bar
      osd-playing-msg=''${filename}

      # ======================================================================
      # 字幕
      # ======================================================================
      sub-font="Noto Sans CJK SC;Noto Color Emoji"
      sub-font-size=50
      sub-bold=yes
      sub-color="#FFFFFF"
      sub-outline-size=0.5
      sub-outline-color="#000000"
      sub-shadow-offset=0.5
      sub-codepage=gb18030
      sub-auto=fuzzy
      sub-file-paths=sub;subs;subtitles;字幕
      slang=chs,sc,zh-Hans,zh-CN,cht,tc,zh-Hant,zh-HK,zh-TW,chi,zho,zh

      # ======================================================================
      # yt-dlp（Bilibili 等网络视频）
      # ======================================================================
      ytdl=yes
      ytdl-format=bestvideo[height<=?2160][vcodec!=?vp9.2]+bestaudio/best

      # ======================================================================
      # 截图
      # ======================================================================
      screenshot-format=webp
      screenshot-webp-quality=85
      screenshot-template="~~/files/screen/%{media-title}-%P-%n"

      # ======================================================================
      # 常规
      # ======================================================================
      save-position-on-quit=yes
      hr-seek=yes
      keep-open=yes
      idle=yes
      ontop                              # 窗口置顶
      save-watch-history=yes
      input-ipc-server=/tmp/mpvsocket
      msg-level=all=info,auto_profiles=warn

      # ======================================================================
      # Bilibili 弹幕（bdanmaku）
      # ======================================================================
      script-opts-append=biliass_executable=biliass
      script-opts-append=curl_executable=curl
    '';
  };

  # Bilibili 弹幕插件脚本 -> ~/.config/mpv/scripts/bdanmaku.lua
  home.file.".config/mpv/scripts/bdanmaku.lua".source =
    "${pkgs.mpvScripts.bdanmaku}/share/mpv/scripts/bdanmaku.lua";

  # ============================================================================
  # exo-open helpers.rc（Thunar 右键"在终端中打开"依赖此配置）
  # ============================================================================
  home.file.".config/xfce4/helpers.rc".text = ''
    TerminalEmulator=kitty
    TerminalEmulatorDismissed=true
  '';
  # ============================================================================
  # Thunar 默认终端设置为 kitty
  #   在每次 activation 时确保 xfconf 属性正确
  # ============================================================================
  home.activation.setThunarTerminal = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Thunar 默认终端
    ${pkgs.xfconf}/bin/xfconf-query -c thunar -p /default-terminal-emulator -s kitty 2>/dev/null || \
    ${pkgs.xfconf}/bin/xfconf-query -c thunar -p /default-terminal-emulator -n -t string -s kitty
    # exo-open 终端模拟器
    ${pkgs.xfconf}/bin/xfconf-query -c xfce4-appfinder -p /terminal-emulator/emulator -s kitty 2>/dev/null || \
    ${pkgs.xfconf}/bin/xfconf-query -c xfce4-appfinder -p /terminal-emulator/emulator -n -t string -s kitty
  '';
}
