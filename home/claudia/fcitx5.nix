{ config, pkgs, lib, ... }:

# ==============================================================================
# Fcitx5 输入法配置 —— DMS 动态配色同步
#
#   本文件管理 Fcitx5 输入法框架的配色与 DMS（DankMaterialShell）的联动，
#   通过 systemd path 监听 + 同步脚本实现 fcitx5 配色跟随壁纸变化。
#
#   设计说明：
#   DMS 会根据壁纸生成动态主题色，但 fcitx5 的候选词窗口使用独立于
#   GTK/Qt 的 classicui 渲染，默认不会跟随 DMS 主题色。
#
#   配色数据来源：
#   与 fuzzel.nix 相同，直接读取 dms-colors.json（而非 DMS matugen 模板）。
#   原因：dms-colors.json 的 colors 对象只有 dark/light 分支，没有 default
#   分支，matugen 模板变量 {{colors.*.default.hex}} 无法正确渲染。
#   脚本根据 session.json 的 isLightMode 选择 dark 或 light 配色方案。
#
#   同步策略：
#   fcitx5 classicui 在 Wayland 原生终端（kitty）中使用内部缓存的主题配色。
#   若 Theme 名不变，即使 theme.conf 内容已更新，classicui 也不会重新读取。
#   因此脚本将 theme.conf 复制到递增目录（dms-0、dms-1 ...），并将
#   classicui.conf 的 Theme 指向递增名，然后通过 fcitx5-remote -r 通知重载。
#
#   关键配置：UseAccentColor=False
#   fcitx5 默认 UseAccentColor=True，会从 XDG portal 读取 accent-color
#   （GNOME 默认橙色）并覆盖 HighlightColor 等配色。由于 DMS 管理主题色
#   但不管 portal accent-color，kitty 等非 GTK/Qt 应用中候选框配色会固定
#   为橙色。添加 UseAccentColor=False 可阻止此覆盖。
#   GTK/Qt 应用不受影响——它们的 IM 模块直接读取应用自身主题，不经 classicui。
#
#   配色映射关系（Material Design → fcitx5 classicui）：
#     NormalColor              = on_surface               # 未选中条目文字
#     HighlightCandidateColor  = on_primary               # 选中候选词文字
#     HighlightColor           = on_primary               # 高亮文字
#     HighlightBackgroundColor = primary                  # 高亮选中背景
#     背景色                   = surface_container_low    # 窗口背景
#     边框色                   = outline_variant          # 边框
#     Menu NormalColor         = on_surface               # 菜单未选中文字
#     Menu HighlightCandidate  = on_primary_container     # 菜单选中候选词
#     Menu Highlight 背景色    = primary                  # 菜单高亮背景
#     Menu Separator           = outline_variant          # 菜单分隔线
# ==============================================================================

{
  # ============================================================================
  # DMS → fcitx5 配色自动同步脚本
  #
  #   读取 dms-colors.json 和 session.json，根据 isLightMode 选择 dark 或
  #   light 配色方案，生成 fcitx5 theme.conf，写入递增目录名以绕过
  #   classicui 的主题缓存，并通过 fcitx5-remote -r 通知重载。
  #
   #   竞态修复：DMS 切换壁纸/模式时 session.json 先更新，
   #   cache/dms-colors.json 后更新。systemd path 单元可能在
   #   session.json 更新后立即触发脚本，而此时 colors.json 尚未刷新。
   #   通过比较 mtime 确保 colors.json 的更新时间 ≥ session.json，
   #   保证读取到的是与当前模式匹配的配色数据。最多等待 10 秒。
   #   方案来自 fuzzel.nix，已验证可靠。
  # ============================================================================

  home.file."${config.home.homeDirectory}/.local/bin/dms-fcitx5-sync" = {
    executable = true;
    source = pkgs.writeShellScript "dms-fcitx5-sync" ''
      DMS_CLR="${config.home.homeDirectory}/.cache/DankMaterialShell/dms-colors.json"
      DMS_SES="${config.home.homeDirectory}/.local/state/DankMaterialShell/session.json"
      THEMES_DIR="${config.home.homeDirectory}/.local/share/fcitx5/themes"
      CNT_FILE="$THEMES_DIR/.sync-counter"
      LOCK_FILE="$THEMES_DIR/.sync.lock"
      CLASSICUI="${config.home.homeDirectory}/.config/fcitx5/conf/classicui.conf"

      [[ -f "$DMS_CLR" && -f "$DMS_SES" ]] || exit 0

      mkdir -p "$THEMES_DIR"
      exec 9>"$LOCK_FILE"
      flock -n 9 || exit 0

      # ==========================================================================
      # 竞态修复：等待 colors.json 刷新后再读取
      #   systemd path 单元可能在 session.json 更新后立即触发，
      #   而此时 colors.json 可能尚未被 DMS 刷新。通过比较
      #   session.json 与 colors.json 的 mtime，确保 colors.json
      #   在 mode 切换之后已完成更新。最多等待 10 秒。
      # ==========================================================================
      SES_MTIME=$(stat -c "%Y" "$DMS_SES" 2>/dev/null || echo 0)
      WAITED=0
      while [ $WAITED -lt 10 ]; do
        CLR_MTIME=$(stat -c "%Y" "$DMS_CLR" 2>/dev/null || echo 0)
        if [ "$CLR_MTIME" -ge "$SES_MTIME" ] 2>/dev/null; then
          break
        fi
        sleep 1
        WAITED=$((WAITED + 1))
      done

      # ==========================================================================
      # 读取 DMS 配色数据 —— 根据 isLightMode 选择 dark 或 light 分支
      #
      #   dms-colors.json 的 colors 对象只有 dark/light 两个子键，
      #   没有 default 分支，因此 DMS matugen 模板无法正确渲染
      #   {{colors.*.default.hex}} 变量。本脚本直接用 jq 读取 JSON 并
      #   根据 session.json 的 isLightMode 选择正确的配色方案。
      # ==========================================================================
      IS_LIGHT=$(${pkgs.jq}/bin/jq -r '.isLightMode' < "$DMS_SES")
      SCHEME=$([ "$IS_LIGHT" = "true" ] && echo "light" || echo "dark")

      # 颜色提取函数：从 dms-colors.json 的 colors.$SCHEME 中取值
      #   输入：Material Design 颜色名（如 primary, on_surface 等）
      #   输出：#RRGGBB 格式的颜色值，找不到时回退为 #000000
      c() { ${pkgs.jq}/bin/jq -r ".colors.$SCHEME.$1 // \"#000000\"" < "$DMS_CLR"; }

      # ==========================================================================
      # 递增主题名 —— 绕过 classicui 的主题缓存
      #
      #   fcitx5 classicui 在 Wayland 原生终端（kitty）中使用内部缓存
      #   的主题配色。如果 Theme 名不变，即使 theme.conf 内容已更新，
      #   classicui 也不会重新读取。递增名（dms-0、dms-1 ...）确保
      #   每次都是"新主题"，classicui 必须从磁盘解析。
      #
      #   使用计数器文件（.sync-counter）而非时间戳，确保目录名稳定递增。
      # ==========================================================================
      COUNTER=0
      [ -f "$CNT_FILE" ] && COUNTER=$(cat "$CNT_FILE")
      NEXT_COUNTER=$((COUNTER + 1))
      THEME_NAME="dms-$COUNTER"
      THEME_DIR="$THEMES_DIR/$THEME_NAME"

      mkdir -p "$THEME_DIR"

      # ==========================================================================
      # 生成 fcitx5 主题文件
      #
      #   使用 Material Design 颜色变量映射到 fcitx5 classicui 各组件。
      #   颜色均来自 DMS 壁纸配色（dms-colors.json），根据当前深浅
      #   模式选择 dark 或 light 分支。
      # ==========================================================================
      SCHEME_LABEL=$([ "$SCHEME" = "light" ] && echo "light" || echo "dark")
      cat > "$THEME_DIR/theme.conf" <<- THEMEEOF
      [Metadata]
      Name=DMS Dynamic ($SCHEME_LABEL)
      Version=1
      Author=DankMaterialShell
      Description=Dynamic DMS theme - $SCHEME_LABEL scheme
      ScaleWithDPI=True

      [InputPanel]
      NormalColor=$(c on_surface)
      HighlightCandidateColor=$(c on_primary)
      HighlightColor=$(c on_primary)
      HighlightBackgroundColor=$(c primary)
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
      Color=$(c surface_container_low)
      BorderColor=$(c outline_variant)
      BorderWidth=2

      [InputPanel/Background/Margin]
      Left=2
      Right=2
      Top=2
      Bottom=2

      [InputPanel/Highlight]
      Color=$(c primary)

      [InputPanel/Highlight/Margin]
      Left=5
      Right=5
      Top=5
      Bottom=5

      [Menu]
      NormalColor=$(c on_surface)
      HighlightCandidateColor=$(c on_primary_container)

      [Menu/Background]
      Color=$(c surface_container_low)
      BorderColor=$(c outline_variant)
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
      Color=$(c primary)

      [Menu/Highlight/Margin]
      Left=5
      Right=5
      Top=5
      Bottom=5

      [Menu/Separator]
      Color=$(c outline_variant)

      [Menu/TextMargin]
      Left=5
      Right=5
      Top=5
      Bottom=5
      THEMEEOF

      echo "$NEXT_COUNTER" > "$CNT_FILE"

      # 重写 classicui.conf —— 递增主题名绕过 classicui 缓存
      #
      #   UseAccentColor=False：阻止 fcitx5 从 XDG portal 读取系统强调色
      #   并覆盖 DMS 主题配色。portal 的 accent-color 为 GNOME 默认值（橙色），
      #   不受 DMS 管理。若不显式关闭，fcitx5 classicui 在 kitty 等非 GTK/Qt
      #   应用（wayland_v2 前端）中会用 portal 强调色覆盖 HighlightColor 等字段，
      #   导致候选框配色固定为橙色，无法跟随 DMS 切换壁纸后的动态配色。
      #   在 GTK/Qt 应用中，fcitx5-gtk/fcitx5-qt IM 模块直接使用应用自身主题，
      #   不经过 classicui，因此不受 UseAccentColor 影响。
      #
      #   UseDarkTheme=False：DMS 已通过递增主题名 + classicui.conf 重写实现
      #   深浅切换，无需 fcitx5 内建的 Follow System Dark/Light 逻辑。
      cat > "$CLASSICUI" <<- CLASSICUIEOF
      # 注意：首行 Theme 必须无 section 头，
      # 因为 fcitx5-gtk ClassicUIConfig 将内容包裹在 [Group] 下解析。
      Theme=$THEME_NAME

      [Config]
      Theme=$THEME_NAME
      UseAccentColor=False
      UseDarkTheme=False
      CLASSICUIEOF

      sync

      # 通知 fcitx5 重新加载配置
      ${pkgs.fcitx5}/bin/fcitx5-remote -r 2>/dev/null || true

      # 清理旧主题目录：保留最近 10 个 dms-* 目录，防止残留过多
      ls -dt "$THEMES_DIR"/dms-[0-9]* 2>/dev/null | tail -n +11 | xargs rm -rf
    '';
  };

  # ============================================================================
  # systemd 触发服务
  # ============================================================================

  systemd.user.services.dms-fcitx5-sync = {
    Unit = { Description = "Sync DMS wallpaper colors to fcitx5 theme"; };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/bin/dms-fcitx5-sync";
      Restart = "no";
      StartLimitBurst = 30;
      StartLimitIntervalSec = 30;
    };
    # WantedBy 不在 service 上 —— 仅由 path 单元触发
  };

  # ---------------------------------------------------------------------------
  # 路径监听说明：
  #   - cache/dms-colors.json：DMS 壁纸配色的主输出文件，每次壁纸切换都会更新
  #   - session.json：记录当前深浅模式，切换壁纸/DMS 模式时更新
  #   - state/dms-colors.json 已从监听列表移除：该文件在壁纸切换时不会更新
  #     （仅在某次 DMS 初始化时写入），监听它会导致用过时配色触发同步
  # ---------------------------------------------------------------------------
  systemd.user.paths.dms-fcitx5-sync = {
    Unit = { Description = "Watch DMS colors and sync to fcitx5 theme"; };
    Path = {
      PathChanged = [
        "%h/.cache/DankMaterialShell/dms-colors.json"
        "%h/.local/state/DankMaterialShell/session.json"
      ];
    };
    Install = { WantedBy = [ "default.target" ]; };
  };

  # ============================================================================
  # fcitx5 classicui 初始主题配置
  #
  #   classicui.conf 格式特殊：首行 Theme= 无 section 头（供 fcitx5-gtk 使用，
  #   其 ClassicUIConfig 将内容包裹在 [Group] 下解析）；下方的 [Config] 段
  #   供 fcitx5-daemon 的 classicui 插件使用。
  #
  #   初始值 Theme=default（fcitx5 内建默认主题），因为 DMS 配色数据在
  #   首次壁纸切换前不可用。dms-fcitx5-sync 脚本首次运行时替换为
  #   唯一主题名（dms-0 → dms-1 ...）。
  #
  #   UseAccentColor=False：阻止 portal 强调色覆盖 DMS 主题配色（详见解脚本注释）。
  #   UseDarkTheme=False：DMS 已通过递增主题名实现深浅切换。
  # ============================================================================
  home.activation.lockFcitx5ClassicuiTheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
    CFG="/home/claudia/.config/fcitx5/conf/classicui.conf"
    mkdir -p "$(dirname "$CFG")"
    cat > "$CFG" <<- 'THEMEEOF'
# 注意：首行 Theme=default 必须无 section 头，因为 fcitx5-gtk 的 ClassicUIConfig
# 将此文件内容包裹在 [Group] 下解析，若首行是 [Config]，Theme 会落在
# [Config] 段而非 [Group]，导致 GTK IM 模块主题回退为 default。
#
# 下面的 [Config] 段供 fcitx5-daemon 的 classicui 插件使用（标准 fcitx5 配置格式）。
# 初值 Theme=default（fcitx5 内建默认主题），因为 DMS 配色数据在首次壁纸切换前不可用。
# dms-fcitx5-sync 脚本首次运行时替换为唯一主题名（dms-0 → dms-1 → ...），
# 每次壁纸切换使用新名称绕过 classicui 的主题缓存。
#
# UseAccentColor=False：阻止 fcitx5 从 XDG portal 读取系统强调色
# 并覆盖 DMS 主题配色。portal 的 accent-color 为 GNOME 默认值（橙色），
# 不受 DMS 管理。若不关闭，fcitx5 classicui 在 kitty 等非 GTK/Qt
# 应用（wayland_v2 前端）中会用 portal 强调色覆盖 HighlightColor 等字段，
# 导致候选框配色固定为橙色，无法跟随 DMS 壁纸配色。
# GTK/Qt 应用的 IM 模块直接使用应用自身主题，不受此影响。
#
# UseDarkTheme=False：深浅切换已由 DMS 递增主题名机制处理，
# 无需 fcitx5 内建的 Follow System Dark/Light 逻辑。
Theme=default

[Config]
Theme=default
UseAccentColor=False
UseDarkTheme=False
THEMEEOF
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

  # ============================================================================
  # 清理旧版 DMS 模板残留
  #
  #   旧版配置通过 home.file 将 DMS matugen 模板（fcitx5-theme.conf、
  #   fcitx5.toml）部署到 ~/.config/dms/templates/，DMS matugen 引擎会将
  #   壁纸配色渲染到 ~/.local/share/fcitx5/themes/dms/theme.conf。
  #
  #   当前版本改为直接从 dms-colors.json 生成主题，不再依赖 DMS 模板
  #   （因为 dms-colors.json 的 colors 对象没有 default 分支，模板变量
  #   {{colors.*.default.hex}} 无法正确选择 dark/light 方案）。
  #
  #   本激活脚本在每次 home-manager switch 后清理旧版模板和孤立目录。
  # ============================================================================
  home.activation.cleanupDmsFcitx5Templates = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # 删除旧版 DMS matugen 模板（不再需要）
    rm -f /home/claudia/.config/dms/templates/fcitx5-theme.conf
    rm -f /home/claudia/.config/dms/templates/fcitx5.toml

    # 删除 DMS matugen 渲染输出的孤立目录
    # 当前脚本直接生成 dms-N/theme.conf，不再使用此目录
    rm -rf /home/claudia/.local/share/fcitx5/themes/dms

    # 清理已部署的旧版本 sync 脚本的锁文件和计数器
    # （保留 dms-N 目录让 classicui 有主题可加载）
    rm -f /home/claudia/.local/share/fcitx5/themes/.sync.lock
  '';
}