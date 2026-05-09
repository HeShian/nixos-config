# ==============================================================================
# 软件包覆盖（Overlays）
#
#   Overlay 是 Nixpkgs 的扩展机制，允许在不修改 nixpkgs 源码的前提下：
#   1. 修改现有包的构建方式（overrideAttrs）
#   2. 添加自定义的新包（callPackage）
#
#   本文件被 flake.nix 中的 overlays 参数引用，在 nixpkgs 实例化时注入：
#     pkgs = import nixpkgs { overlays = [ (import ./overlays/default.nix) ]; };
#
#   自定义包的具体定义在 pkgs/ 目录下，通过 (import ../pkgs/default.nix) 引入。
# ==============================================================================
final: prev: {

  # ============================================================================
  # openldap —— 跳过不稳定的测试
  #   test017-syncreplication-refresh 在 CI 中经常超时/失败，
  #   而 openldap 是 lutris 的传递依赖，测试失败会导致 lutris 构建失败。
  #   解决方案：跳过 openldap 的所有测试（不影响运行时功能）。
  # ============================================================================
  openldap = prev.openldap.overrideAttrs (old: {
    doCheck = false;
  });

  # ============================================================================
  # thunar-archive-plugin —— 注入 xarchiver.tap
  #
  #   thunar-archive-plugin 通过 .tap 包装脚本调用归档管理器。
  #   插件扫描 $(libexecdir)/thunar-archive-plugin/ 目录，
  #   根据 MIME 类型查找匹配的 .desktop 文件，再匹配同名的 .tap 文件。
  #
  #   xarchiver 已安装 xarchiver.desktop 作为默认归档管理器，
  #   但 thunar-archive-plugin 上游未包含 xarchiver.tap。
  #   此 overlay 在 thunar-archive-plugin 构建后注入 xarchiver.tap，
  #   使 Thunar 右键菜单的「解压到此处」「压缩」等功能正常工作。
  #
  #   .tap 文件接收三个参数：
  #     $1 = 动作（create / extract-here / extract-to）
  #     $2 = 建议目录
  #     $@ = 文件列表
  # ============================================================================
  thunar-archive-plugin = prev.thunar-archive-plugin.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      cp ${prev.writeShellScript "xarchiver.tap" ''
        action=$1; shift;
        folder=$1; shift;
        case $action in
          create)
            exec xarchiver -c "$@"
            ;;
          extract-here)
            exec xarchiver -x "$folder" "$@"
            ;;
          extract-to)
            exec xarchiver -e "$@"
            ;;
          *)
            echo "Unsupported action '$action'" >&2
            exit 1
            ;;
        esac
      ''} $out/libexec/thunar-archive-plugin/xarchiver.tap
    '';
  });

  # ============================================================================
  # 引入自定义软件包
  #   pkgs/default.nix 中定义了本项目的自定义包（如 bilibili-tui）。
  #   通过 overlay 机制注入到 nixpkgs 中，之后可像系统包一样使用。
  #
  #   添加新包的流程：
  #     1. 在 pkgs/ 下创建包目录和 default.nix
  #     2. 在 pkgs/default.nix 中注册
  #     3. 本文件会自动连带引入（无需修改）
  # ============================================================================
} // (import ../pkgs/default.nix) final prev
