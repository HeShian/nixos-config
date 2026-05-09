{ config, pkgs, inputs, ... }:

# ==============================================================================
# CookNixvim —— 基于 Nixvim 的模块化 Neovim 配置
#
#   CookNixvim 是一个外部 flake 输入，提供预配置的 Neovim 发行版。
#   与传统手动管理 Neovim 配置（vimrc + 插件管理器）相比的优势：
#
#   - 零污染：所有插件和 LSP 工具都由 Nix 管理，不会污染 ~/.local/share/nvim
#   - 声明式：所有配置写在一个地方，可版本控制、可复现
#   - 隔离：Neovim 运行时完全由 Nix store 路径决定，不受系统 Python/Node 版本影响
#
#   本文件创建自定义包装脚本，在 CookNixvim 的基础上注入自定义快捷键，
#   无需 fork 上游仓库。
#
#   ⚠️ Ctrl+Shift+C 在多数终端模拟器中会被终端自身拦截为"复制"操作。
#   如需在 nvim 中使用此快捷键，需配置终端不再拦截该组合键：
#     kitty:  map ctrl+shift+c no_op  （加入 kitty.conf）
#     若终端未放行，可使用 vim 自带快捷键：可视模式下按 y 即可复制
#     （CookNixvim 已配置 clipboard=unnamedplus，y 直接复制到系统剪贴板）
#
#   参考：https://github.com/Youthdreamer/CookNixvim
#   独立仓库：CookNixvim 有自己独立的构建和发布节奏
# ==============================================================================

let
  # CookNixvim 预编译的 neovim 包（完整运行时 + 配置）
  cookNixvim = inputs.CookNixvim.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # 自定义快捷键 Lua 脚本
  #   这些映射在 CookNixvim 的 init.lua 之前通过 --cmd 加载，
  #   只要 CookNixvim 自身的 keymaps 不动 <C-S-c> 就不会冲突
  customKeymaps = pkgs.writeText "sisyphus-keymaps.lua" ''
    -- ============================================================
    -- Sisyphus 自定义快捷键
    --   在 CookNixvim 配置加载前注入，优先级低于插件 keymaps
    -- ============================================================

    -- Ctrl+Shift+C：复制选中文本到系统剪贴板（可视模式）
    --   效果等同于可视模式下按 y（CookNixvim 已设 clipboard=unnamedplus）
    vim.keymap.set('v', '<C-S-c>', '"+y', { desc = '复制到系统剪贴板' })

    -- Ctrl+Shift+C：复制当前行到系统剪贴板（普通模式）
    vim.keymap.set('n', '<C-S-c>', '"+yy', { desc = '复制当前行到系统剪贴板' })
  '';
in
{
  home = {
    # 安装带自定义快捷键的 nvim 包装器
    #   使用自定义 shell 脚本而非 makeWrapper，因为 makeWrapper 的
    #   --add-flags 在参数含空格时会因内部展开不带引号而导致词分割
    packages = [
      (pkgs.runCommand "nvim-with-custom-keymaps"
        {
          meta.mainProgram = "nvim";
        }
        ''
          mkdir -p $out/bin
          cat > $out/bin/nvim << 'WRAPPER'
#!/bin/sh
WRAPPER
          # 将 Nix store 路径注入包装脚本（heredoc 无引号，允许 Nix 变量展开）
          echo "exec ${cookNixvim}/bin/nvim --cmd \"luafile ${customKeymaps}\" \"\$@\"" >> $out/bin/nvim
          chmod +x $out/bin/nvim
        ''
      )
    ];

    # 设置默认编辑器环境变量
    # EDITOR 和 VISUAL 影响众多命令行工具（git commit、crontab -e 等）
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };
}
