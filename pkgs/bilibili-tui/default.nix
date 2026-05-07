# ==============================================================================
# bilibili-tui —— 终端版 Bilibili 客户端
#
#   使用 Rust 编写的 B 站 TUI 客户端，支持：
#   - 视频浏览与搜索
#   - 直播观看
#   - 弹幕显示
#   - 本地收藏管理
#
#   来源：GitHub (MareDevi/bilibili-tui)
#   版本：1.0.11
#
#   依赖说明：
#   - pkg-config：自动检测已安装的库（如 openssl）
#   - openssl：HTTPS 通信所需
#   运行时依赖（在 home/claudia/default.nix 中声明的用户级包）：
#   - mpv：视频播放后端
#   - yt-dlp：视频流地址解析
#   - bdanlaku mpv 插件 + biliass：弹幕支持
# ==============================================================================
{ lib
, fetchFromGitHub
, rustPlatform
, pkg-config
, openssl
}:

rustPlatform.buildRustPackage rec {
  pname = "bilibili-tui";
  version = "1.0.11";

  # 从 GitHub 拉取源码（基于 Git tag）
  src = fetchFromGitHub {
    owner = "MareDevi";
    repo = "bilibili-tui";
    rev = "v${version}";
    hash = "sha256-QHggUJKxZTex5pb/xtolBYbZLr7ozoSIlXlVPDu+WhI=";
  };

  # Cargo.lock 的哈希（Rust 依赖锁定）
  cargoHash = "sha256-ABL2qo8XUVxqeRESlAhLxwxrzo0rd8vaesHFFmhdBk0=";

  # 跳过 Rust 测试（部分测试需要网络/B站 API，本地构建不可用）
  doCheck = false;

  nativeBuildInputs = [ pkg-config ];   # 构建时依赖
  buildInputs = [ openssl ];            # 运行时链接依赖

  meta = {
    description = "A terminal user interface (TUI) client for Bilibili";
    homepage = "https://github.com/MareDevi/bilibili-tui";
    license = lib.licenses.mit;
    mainProgram = "bilibili-tui";       # 指定可执行文件名
  };
}
