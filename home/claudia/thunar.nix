{ config, pkgs, lib, ... }:

# ==============================================================================
# Thunar 桌面集成（用户级配置）
#
#   本文件管理 Thunar 文件管理器的用户级配置，包括：
#   - ~/Templates/ 文件模板（右键"创建文档"菜单）
#   - Neovim 桌面入口（双击文本文件以 nvim 打开）
#   - 自定义右键解压动作（uca.xml）
#   - exo-open helpers.rc（终端模拟器设置）
#   - Thunar 默认终端配置（xfconf）
#   - exo-open 终端模拟器（xfce4-appfinder）
#
#   系统级 Thunar 配置（程序包、插件）请见 hosts/westwood/thunar.nix
# ==============================================================================

{
  # ============================================================================
  # 文件模板 —— 右键"创建文档"菜单
  #
  #   将模板文件部署到 ~/Templates/ 目录，Thunar 会自动识别并在
  #   右键菜单"创建文档"中列出，选择后会在当前目录生成对应副本。
  #
  #   模板文件列表：
  #   - 空白文本文件.txt     → 空文本文件
  #   - Shell 脚本.sh        → 带 shebang 和注释的 Shell 脚本
  #   - Python 脚本.py       → 带 shebang 和编码声明的 Python 脚本
  #   - Markdown 文档.md     → 带标题占位的 Markdown 文档
  # ============================================================================
  home.file = {
    # --- 空白文本文件 ---
    "Templates/空白文本文件.txt".text = "";

    # --- Shell 脚本模板 ---
    "Templates/Shell 脚本.sh".text = ''
      #!/usr/bin/env bash
      # ==============================================================================
      # 脚本说明
      # ==============================================================================
      set -euo pipefail

    '';

    # --- Python 脚本模板 ---
    "Templates/Python 脚本.py".text = ''
      #!/usr/bin/env python3
      # -*- coding: utf-8 -*-

      def main():
          pass

      if __name__ == "__main__":
          main()

    '';

    # --- Markdown 文档模板 ---
    "Templates/Markdown 文档.md".text = ''
      # 标题

      ## 概述

      ## 详细说明

    '';

    # ============================================================================
    # exo-open helpers.rc（Thunar 右键"在终端中打开"依赖此配置）
    # ============================================================================
    ".config/xfce4/helpers.rc".text = ''
      TerminalEmulator=ghostty
      TerminalEmulatorDismissed=true
    '';

    # ============================================================================
    # Thunar 自定义右键动作（uca.xml）
    #
    #   通过 uca.xml 提供增强的右键压缩/解压菜单：
    #   - 解压到此处（支持 tar.gz / tar.bz2 / tar.xz / zip / 7z / rar）
    #   - 解压到子目录
    #   - 压缩为 tar.gz / zip
    #
    #   注意：thunar-archive-plugin（系统级）已提供基本的压缩/解压
    #   集成；本文件中的 uca.xml 作为额外补充，覆盖更多格式和场景。
    # ============================================================================
    ".config/Thunar/uca.xml" = {
      text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <actions>
        <!-- ═══════════════════════════════════════════════════════════════════
             解压到此处（Extract Here）
             支持：tar.gz / tar.bz2 / tar.xz / zip / 7z / rar
             ═══════════════════════════════════════════════════════════════════ -->
        <action>
          <icon>package-x-generic</icon>
          <name>解压到此处</name>
          <submenu></submenu>
          <unique-id>1748952000000001</unique-id>
          <command>bash -c 'f=%f; case "$f" in *.tar.gz|*.tgz) tar xzf "$f" ;; *.tar.bz2|*.tbz2) tar xjf "$f" ;; *.tar.xz|*.txz) tar xJf "$f" ;; *.tar.zst) tar --zstd -xf "$f" ;; *.zip) unzip "$f" ;; *.7z) 7z x "$f" ;; *.rar) unrar x "$f" ;; *.tar) tar xf "$f" ;; *.gz) gunzip -k "$f" ;; *.bz2) bunzip2 -k "$f" ;; *.xz) unxz -k "$f" ;; esac'</command>
          <description>将选中的压缩包解压到当前目录</description>
          <range></range>
          <patterns>*.tar.gz;*.tgz;*.tar.bz2;*.tbz2;*.tar.xz;*.txz;*.tar.zst;*.zip;*.7z;*.rar;*.tar;*.gz;*.bz2;*.xz</patterns>
          <audio-files/>
          <image-files/>
          <other-files/>
          <text-files/>
          <directories/>
        </action>

        <!-- ═══════════════════════════════════════════════════════════════════
             解压到子目录（Extract To...）
             ═══════════════════════════════════════════════════════════════════ -->
        <action>
          <icon>package-x-generic</icon>
          <name>解压到子目录</name>
          <submenu></submenu>
          <unique-id>1748952000000002</unique-id>
          <command>bash -c 'f=%f; dir="''${f%%.*}" && mkdir -p "$dir" && case "$f" in *.tar.gz|*.tgz) tar xzf "$f" -C "$dir" ;; *.tar.bz2|*.tbz2) tar xjf "$f" -C "$dir" ;; *.tar.xz|*.txz) tar xJf "$f" -C "$dir" ;; *.tar.zst) tar --zstd -xf "$f" -C "$dir" ;; *.zip) unzip "$f" -d "$dir" ;; *.7z) 7z x "$f" -o"$dir" ;; *.rar) unrar x "$f" "$dir/" ;; *.tar) tar xf "$f" -C "$dir" ;; esac'</command>
          <description>将选中的压缩包解压到以文件名命名的子目录中</description>
          <range></range>
          <patterns>*.tar.gz;*.tgz;*.tar.bz2;*.tbz2;*.tar.xz;*.txz;*.tar.zst;*.zip;*.7z;*.rar;*.tar</patterns>
          <audio-files/>
          <image-files/>
          <other-files/>
          <text-files/>
          <directories/>
        </action>

        <!-- ═══════════════════════════════════════════════════════════════════
             压缩为 tar.gz
             ═══════════════════════════════════════════════════════════════════ -->
        <action>
          <icon>package-x-generic</icon>
          <name>压缩为 tar.gz</name>
          <submenu></submenu>
          <unique-id>1748952000000003</unique-id>
          <command>bash -c 'tar czf "''$(basename %f).tar.gz" %F'</command>
          <description>将选中文件/文件夹打包为 tar.gz</description>
          <range>*</range>
          <patterns>*</patterns>
          <audio-files/>
          <image-files/>
          <other-files/>
          <text-files/>
          <directories/>
        </action>

        <!-- ═══════════════════════════════════════════════════════════════════
             压缩为 zip
             ═══════════════════════════════════════════════════════════════════ -->
        <action>
          <icon>package-x-generic</icon>
          <name>压缩为 zip</name>
          <submenu></submenu>
          <unique-id>1748952000000004</unique-id>
          <command>bash -c 'zip -r "''$(basename %f).zip" %F'</command>
          <description>将选中文件/文件夹打包为 zip</description>
          <range>*</range>
          <patterns>*</patterns>
          <audio-files/>
          <image-files/>
          <other-files/>
          <text-files/>
          <directories/>
        </action>
      </actions>
    '';
      force = true;
    };
  };

  # ============================================================================
  # Neovim 桌面入口 —— 双击文本文件以 nvim（在 ghostty 终端中）打开
  #
  #   为 Neovim 创建一个 .desktop 文件，使其出现在桌面环境的
  #   应用启动器和"打开方式"菜单中。配合 xdg.nix 中的 MIME 关联，
  #   在 Thunar 中双击文本文件即可用 neovim 打开。
  #
  #   %F = 文件路径列表（支持多文件）
  #   --class nvim = Wayland 窗口类名，方便 niri 配置窗口规则
  # ============================================================================
  xdg.desktopEntries.nvim = {
    name = "Neovim";
    genericName = "文本编辑器";
    comment = "使用 Neovim 编辑文本文件";
    exec = "ghostty --class=nvim -e nvim %F";
    icon = "nvim";
    terminal = false;                    # ghostty 自行提供终端，不需要外部启动器模拟终端
    categories = [ "Utility" "TextEditor" ];
    mimeType = [
      # --- 通用文本 ---
      "text/plain"
      "text/x-readme"
      "text/x-log"
      # --- 编程语言源码 ---
      "text/x-shellscript"
      "text/x-python"
      "text/x-csrc"
      "text/x-c++src"
      "text/x-c"
      "text/x-chdr"
      "text/x-c++hdr"
      "text/x-makefile"
      "text/x-nix"
      "text/x-lua"
      "text/x-rust"
      "text/x-go"
      "text/x-java"
      "text/x-javascript"
      "text/x-typescript"
      "text/css"
      "text/x-html"
      "text/x-sql"
      # --- 配置文件格式 ---
      "text/x-toml"
      "text/x-yaml"
      "text/x-json"
      "text/x-ini"
      "text/x-diff"
      "text/x-patch"
      # --- 标记语言 ---
      "text/x-markdown"
      "text/x-rst"
      "text/x-tex"
      # --- 其他 ---
      "application/json"
      "application/x-shellscript"
      "application/x-python"
      "application/xml"
      "application/x-yaml"
      "inode/x-empty"                   # 空文件也关联 neovim
    ];
  };

  # ============================================================================
  # Thunar 默认终端设置为 ghostty
  #   在每次 activation 时确保 xfconf 属性正确
  # ---------------------------------------------------------------------------
  # setThunarTerminal：在 activation 阶段设置 Thunar 默认终端
  #
  #   xfconf-query 需要用户 D-Bus 会话（DBUS_SESSION_BUS_ADDRESS 环境变量）。
  #   在系统启动时（home-manager-claudia.service）D-Bus 可能尚未就绪，
  #   导致 xfconf-query 退出非零。为避免阻断整个 HM activation，
  #   将错误静默处理 —— 桌面会话启动时 DMS/GTK sync 服务会重新设置此值。
  # ---------------------------------------------------------------------------
  home.activation.setThunarTerminal = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [[ -n "$DBUS_SESSION_BUS_ADDRESS" ]]; then
      ${pkgs.xfconf}/bin/xfconf-query -c thunar -p /default-terminal-emulator -s ghostty 2>/dev/null || \
      ${pkgs.xfconf}/bin/xfconf-query -c thunar -p /default-terminal-emulator -n -t string -s ghostty 2>/dev/null
      ${pkgs.xfconf}/bin/xfconf-query -c xfce4-appfinder -p /terminal-emulator/emulator -s ghostty 2>/dev/null || \
      ${pkgs.xfconf}/bin/xfconf-query -c xfce4-appfinder -p /terminal-emulator/emulator -n -t string -s ghostty 2>/dev/null
    fi
    true  # 永不因 xfconf 不可用而阻断 HM activation
  '';
}
