{ config, pkgs, ... }:

# ==============================================================================
# Shell 环境配置
#
#   本文件管理用户 claudia 的 Shell 环境和终端体验，包括：
#
#   1. Shell 本身：fish（禁用 bash，启用 fish 作为默认登录 Shell）
#   2. 提示符：starship（Catppuccin Mocha 配色，Powerline 风格）
#   3. 目录跳转：zoxide（智能 cd，自动学习常用目录）
#   4. 终端：kitty（GPU 加速终端，Nerd Font 集成）
#
#   fish 的交互式初始化（别名、环境变量、历史设置）在
#   programs.fish.interactiveShellInit 中定义。
# ==============================================================================

{
  # ============================================================================
  # fish —— 现代交互式 Shell
  #
  #   禁用 bash，启用 fish 作为默认登录 Shell。
  #   fish 的优点：
  #   - 开箱即用的语法高亮和自动建议
  #   - 友好的 Web 界面配置（fish_config）
  #   - 优秀的脚本补全系统
  #
  #   注意：在 packages.nix 中 programs.fish.enable = true 是系统级启用
  #   （注册到 /etc/shells），这里 programs.fish.enable = true 是用户级接管
  #   （设为默认登录 Shell）。
  # ============================================================================
  programs.bash.enable = false;                    # 禁用 bash（不安装，不注册）

  programs.fish = {
    enable = true;                                  # 启用 fish，设为默认登录 Shell

    # fish 交互式 Shell 的额外初始化代码
    # 这些代码在每次打开新终端时执行
    interactiveShellInit = ''
      # ===== 关闭欢迎语 =====
      set -g fish_greeting

      # ===== 自定义别名（eza/bat 替代 ls/cat） =====
      alias ll='eza -la --icons'
      alias la='eza -A --icons'
      alias l='eza -CF --icons'
      alias lt='eza --icons --tree'                 # 树形目录
      alias cat='bat'                                # 彩色 cat
      alias ..='cd ..'
      alias ..2='cd ../..'
      alias ..3='cd ../../..'

      # ===== Git 快捷操作 =====
      alias gs='git status'
      alias gc='git commit'
      alias gp='git push'
      alias gl='git log --oneline --graph'

      # ===== 环境变量 =====
      set -gx EDITOR nvim
      set -gx VISUAL nvim
      set -gx PATH ~/.local/bin $PATH               # 本地二进制文件优先

      # ===== 历史记录设置 =====
      set -g fish_history_size 10000
    '';
  };

  # ============================================================================
  # zoxide —— 智能目录跳转工具
  #
  #   记录 cd 历史的目录频率和时效性，
  #   使用 z <部分名字> 即可跳转到最匹配的目录。
  #   替代传统的 cd 和目录别名。
  # ============================================================================
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;                   # 注册 z 命令到 fish
  };

  # ============================================================================
  # Starship —— 跨 Shell 提示符
  #
  #   使用 Catppuccin Powerline 预设（Mocha 配色方案），
  #   显示：OS 图标 → 用户名 → 当前目录 → Git 分支/状态 → 语言版本 → 时间
  #   配色参考：https://starship.rs/presets/catppuccin-powerline
  # ============================================================================
  programs.starship = {
    enable = true;
    enableFishIntegration = true;

    # Catppuccin Powerline 风格配置（v1.0.0）
    settings = {
      format = "[](red)$os$username[](bg:peach fg:red)$directory[](bg:yellow fg:peach)$git_branch$git_status[](fg:yellow bg:green)$c$rust$golang$nodejs$bun$php$java$kotlin$haskell$python[](fg:green bg:sapphire)$conda[](fg:sapphire bg:lavender)$time[ ](fg:lavender)$cmd_duration$line_break$character";

      palette = "catppuccin_mocha";

      # ---- 各模块配置 ----
      # 各模块的 style 属性使用 bg:背景 fg:前景 格式，
      # 颜色值对应下方 palettes 中定义的颜色名称

      os = {
        disabled = false;
        style = "bg:red fg:crust";
        symbols = {
          Linux = "󰌽";
          Macos = "󰀵";
          Windows = "";
          Arch = "󰣇";
          # ...（其他系统符号如需要可重新添加）
        };
      };

      username = {
        show_always = true;
        style_user = "bg:red fg:crust";
        style_root = "bg:red fg:crust";
        format = "[ $user]($style)";
      };

      directory = {
        style = "bg:peach fg:crust";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = "󰝚 ";
          "Pictures" = " ";
          "Developer" = "󰲋 ";
        };
      };

      git_branch = {
        symbol = "";
        style = "bg:yellow";
        format = "[[ $symbol $branch ](fg:crust bg:yellow)]($style)";
      };

      git_status = {
        style = "bg:yellow";
        format = "[[($all_status$ahead_behind )](fg:crust bg:yellow)]($style)";
      };

      # ---- 语言版本模块 ----
      # 检测当前目录的项目语言并显示版本号
      # 仅当目录中有对应语言的配置文件时才显示

      c = { symbol = " "; style = "bg:green"; format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)"; };
      rust = { symbol = ""; style = "bg:green"; format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)"; };
      golang = { symbol = ""; style = "bg:green"; format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)"; };
      nodejs = { symbol = ""; style = "bg:green"; format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)"; };
      bun = { symbol = ""; style = "bg:green"; format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)"; };
      php = { symbol = ""; style = "bg:green"; format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)"; };
      java = { symbol = " "; style = "bg:green"; format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)"; };
      kotlin = { symbol = ""; style = "bg:green"; format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)"; };
      haskell = { symbol = ""; style = "bg:green"; format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)"; };
      python = { symbol = ""; style = "bg:green"; format = "[[ $symbol( $version)(\\(#$virtualenv\\)) ](fg:crust bg:green)]($style)"; };

      docker_context = {
        symbol = "";
        style = "bg:sapphire";
        format = "[[ $symbol( $context) ](fg:crust bg:sapphire)]($style)";
      };

      conda = {
        symbol = "  ";
        style = "fg:crust bg:sapphire";
        format = "[$symbol$environment ]($style)";
        ignore_base = false;
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:lavender";
        format = "[[  $time ](fg:crust bg:lavender)]($style)";
      };

      # 禁用默认换行（由我们的 format 控制）
      line_break = { disabled = true; };

      character = {
        disabled = false;
        success_symbol = "[❯](bold fg:green)";
        error_symbol = "[❯](bold fg:red)";
        vimcmd_symbol = "[❮](bold fg:green)";
        vimcmd_replace_one_symbol = "[❮](bold fg:lavender)";
        vimcmd_replace_symbol = "[❮](bold fg:lavender)";
        vimcmd_visual_symbol = "[❮](bold fg:yellow)";
      };

      cmd_duration = {
        show_milliseconds = true;
        format = " in $duration ";
        style = "bg:lavender";
        disabled = false;
        show_notifications = true;                 # 命令超过 min_time 时发送通知
        min_time_to_notify = 45000;                # 45 秒
      };

      # ---- Catppuccin 配色方案 ----
      palettes = {
        catppuccin_mocha = {
          rosewater = "#f5e0dc"; flamingo = "#f2cdcd"; pink = "#f5c2e7";
          mauve = "#cba6f7"; red = "#f38ba8"; maroon = "#eba0ac";
          peach = "#fab387"; yellow = "#f9e2af"; green = "#a6e3a1";
          teal = "#94e2d5"; sky = "#89dceb"; sapphire = "#74c7ec";
          blue = "#89b4fa"; lavender = "#b4befe"; text = "#cdd6f4";
          subtext1 = "#bac2de"; subtext0 = "#a6adc8"; overlay2 = "#9399b2";
          overlay1 = "#7f849c"; overlay0 = "#6c7086"; surface2 = "#585b70";
          surface1 = "#45475a"; surface0 = "#313244"; base = "#1e1e2e";
          mantle = "#181825"; crust = "#11111b";
        };
        # 其他配色方案（frappe/latte/macchiato）如需可从此处展开
        catppuccin_frappe = {
          rosewater = "#f2d5cf"; flamingo = "#eebebe"; pink = "#f4b8e4";
          mauve = "#ca9ee6"; red = "#e78284"; maroon = "#ea999c";
          peach = "#ef9f76"; yellow = "#e5c890"; green = "#a6d189";
          teal = "#81c8be"; sky = "#99d1db"; sapphire = "#85c1dc";
          blue = "#8caaee"; lavender = "#babbf1"; text = "#c6d0f5";
          subtext1 = "#b5bfe2"; subtext0 = "#a5adce"; overlay2 = "#949cbb";
          overlay1 = "#838ba7"; overlay0 = "#737994"; surface2 = "#626880";
          surface1 = "#51576d"; surface0 = "#414559"; base = "#303446";
          mantle = "#292c3c"; crust = "#232634";
        };
        catppuccin_latte = {
          rosewater = "#dc8a78"; flamingo = "#dd7878"; pink = "#ea76cb";
          mauve = "#8839ef"; red = "#d20f39"; maroon = "#e64553";
          peach = "#fe640b"; yellow = "#df8e1d"; green = "#40a02b";
          teal = "#179299"; sky = "#04a5e5"; sapphire = "#209fb5";
          blue = "#1e66f5"; lavender = "#7287fd"; text = "#4c4f69";
          subtext1 = "#5c5f77"; subtext0 = "#6c6f85"; overlay2 = "#7c7f93";
          overlay1 = "#8c8fa1"; overlay0 = "#9ca0b0"; surface2 = "#acb0be";
          surface1 = "#bcc0cc"; surface0 = "#ccd0da"; base = "#eff1f5";
          mantle = "#e6e9ef"; crust = "#dce0e8";
        };
        catppuccin_macchiato = {
          rosewater = "#f4dbd6"; flamingo = "#f0c6c6"; pink = "#f5bde6";
          mauve = "#c6a0f6"; red = "#ed8796"; maroon = "#ee99a0";
          peach = "#f5a97f"; yellow = "#eed49f"; green = "#a6da95";
          teal = "#8bd5ca"; sky = "#91d7e3"; sapphire = "#7dc4e4";
          blue = "#8aadf4"; lavender = "#b7bdf8"; text = "#cad3f5";
          subtext1 = "#b8c0e0"; subtext0 = "#a5adcb"; overlay2 = "#939ab7";
          overlay1 = "#8087a2"; overlay0 = "#6e738d"; surface2 = "#5b6078";
          surface1 = "#494d64"; surface0 = "#363a4f"; base = "#24273a";
          mantle = "#1e2030"; crust = "#181926";
        };
      };
    };
  };

  # ============================================================================
  # kitty —— GPU 加速终端模拟器
  #
  #   特性：GPU 渲染、连字支持、多窗口分屏、远程协议（SSH 集成）
  #   字体：JetBrainsMono Nerd Font（等宽 + 图标）
  #   透明度：15% 背景透明（需要合成器支持）
  # ============================================================================
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 13;
    };
    extraConfig = ''
      # 背景透明度 85%
      background_opacity 0.85
      # 窗口内边距
      window_padding_width 5
      # 隐藏窗口标题栏（niri 管理装饰）
      hide_window_decorations yes
      # 关闭窗口时不确认
      confirm_os_window_close 0
      # 鼠标追踪尾迹
      cursor_trail 1
      # 方块光标
      cursor_shape block
      # Shell 集成（禁用光标闪烁）
      shell_integration no-cursor
    '';
  };
}
