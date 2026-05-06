{ config, lib, pkgs, ... }:

# ==============================================================================
# 本地化配置
#   时区、语言环境、键盘布局、中文输入法
# ==============================================================================

{
  # ============================================================================
  # 时区与语言
  # ============================================================================
  time.timeZone = "Asia/Shanghai";             # 北京时间（CST, UTC+8）
  i18n.defaultLocale = "zh_CN.UTF-8";          # 系统默认语言：简体中文 UTF-8

  # 控制台字体与键盘布局
  console = {
    font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
    useXkbConfig = true;                       # 复用 X11 键盘配置
  };

  # ============================================================================
  # 中文输入法 —— Fcitx5 + 中州韵（Rime）+ 雾凇拼音词库
  # ============================================================================
  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.addons = with pkgs; [
      fcitx5-rime                              # Rime 输入法引擎
      kdePackages.fcitx5-chinese-addons        # 拼音/双拼/五笔等中文输入法
      rime-ice                                  # 雾凇拼音 —— 现代简体中文词库
    ];
  };

  # 输入法环境变量 —— 确保 GTK/Qt 应用正确使用 Fcitx5
  environment.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };
}
