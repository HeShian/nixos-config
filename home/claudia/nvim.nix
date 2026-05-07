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
#   参考：https://github.com/Youthdreamer/CookNixvim
#   独立仓库：CookNixvim 有自己独立的构建和发布节奏
# ==============================================================================

{
  home = {
    # 安装 CookNixvim 包（替代 nixpkgs 中的原生 neovim）
    # 通过 flake inputs 引入，确保版本锁定
    packages = [
      inputs.CookNixvim.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    # 设置默认编辑器环境变量
    # EDITOR 和 VISUAL 影响众多命令行工具（git commit、crontab -e 等）
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };
}
