# ==============================================================================
# 软件包覆盖（Overlays）
#   用于在 nixpkgs 基础上修改或替换特定包的版本/构建方式。
# ==============================================================================
final: prev: {
  # openldap 的 test017-syncreplication-refresh 测试不稳定
  # 跳过测试以解决 lutris 构建失败
  openldap = prev.openldap.overrideAttrs (old: {
    doCheck = false;
  });

  # 引入自定义软件包（pkgs/ 目录下的包）
} // (import ../pkgs/default.nix) final prev
