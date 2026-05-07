{ config, lib, pkgs, ... }:

# ==============================================================================
# 字体配置
#
#   本文件管理系统的字体包和 fontconfig 渲染优化。
#
#   搭配方案：
#   - JetBrainsMono Nerd Font → 等宽字体 + 完整图标（Powerline/Devicons 等）
#   - Nerd Font Symbols Only → 仅图标包（减少体积）
#   - Noto Sans CJK SC → 中文界面字体（Google 出品，覆盖简繁日韩）
#   - Noto Color Emoji → 彩色 Emoji 支持
#
#   fontconfig 渲染优化：
#   - antialias：标准抗锯齿
#   - slight hinting：轻微微调（保留字形自然形状）
#   - RGB subpixel LCD 过滤：标准液晶屏最佳效果
#
#   参考：https://github.com/SHORiN-KiWATA/shorin-dms-niri
# ==============================================================================

{
  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono                   # JetBrains Mono + 完整 Nerd Font 图标
      nerd-fonts.symbols-only                     # Nerd Font 图标单独包（补充）
      noto-fonts-cjk-sans                         # Noto Sans CJK —— 中文界面字体
      noto-fonts-color-emoji                      # 彩色 Emoji 字体
    ];

    fontconfig = {
      antialias = true;                           # 启用抗锯齿
      hinting = {
        enable = true;
        style = "slight";                        # slight hinting —— 保留字形轮廓，避免过度变形
      };
      subpixel = {
        rgba = "rgb";                            # 标准 RGB 子像素排列
        lcdfilter = "default";                   # LCD 次像素过滤（改善彩色边缘）
      };
      defaultFonts = {
        monospace = ["JetBrainsMono Nerd Font" "Noto Sans CJK SC"];
        sansSerif = ["Noto Sans CJK SC" "Noto Sans"];
        serif = ["Noto Sans CJK SC" "Noto Sans"];
        emoji = ["Noto Color Emoji"];
      };
    };
  };
}
