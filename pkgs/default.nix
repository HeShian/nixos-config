# ==============================================================================
# 自定义软件包集合（Overlay 形式）
#
#   本文件被 ../overlays/default.nix 引入，以 overlay 函数的形式
#   将自定义包注入 nixpkgs。最终呈现效果如同这些包是 nixpkgs 原生的一部分。
#
#   包的构建定义放在各自的子目录中（如 ./bilibili-tui/），
#   在此处通过 callPackage 统一注册。
#
#   添加新包的步骤：
#     1. 创建 pkgs/<包名>/default.nix（标准 Nix 包定义）
#     2. 在本文件中添加一行：<包名> = final.callPackage ./<包名> { };
#     3. 在 overlays/default.nix 中确认引入（自动引入，通常无需修改）
# ==============================================================================
final: prev: {
  # bilibili-tui —— 终端版 Bilibili 客户端（Rust 实现）
  # 源码来自 GitHub: MareDevi/bilibili-tui
  # 构建跳过测试（doCheck = false），详见包定义
  bilibili-tui = final.callPackage ./bilibili-tui { };
}
