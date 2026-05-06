{ config, pkgs, inputs, ... }:

# ==============================================================================
# CookNixvim —— 基于 Nixvim 的模块化 Neovim 配置
#   参考：https://github.com/Youthdreamer/CookNixvim
#   零污染：所有插件与工具依赖均由 Nix 隔离管理
#   开箱即用：深度集成 LSP、补全、调试、UI 增强
# ==============================================================================

{
  home = {
    # 安装 CookNixvim（替代原生 Neovim）
    packages = [
      inputs.CookNixvim.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
    # 设置默认编辑器
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };
}
