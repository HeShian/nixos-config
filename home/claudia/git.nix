{ config, pkgs, ... }:

# ==============================================================================
# Git 版本控制配置
#
#   本文件管理 Git 的全局用户级设置，包括：
#   - 用户身份：提交时使用的用户名和邮箱
#   - 核心行为：默认分支名、pull 策略、换行符处理
#   - 命令别名：常用操作的快捷方式
#   - 忽略规则：全局 .gitignore
#
#   Home Manager 接管后，这些设置会写入 ~/.config/git/config，
#   手动编辑 ~/.gitconfig 会被覆盖。
# ==============================================================================

{
  programs.git = {
    enable = true;

    # --------------------------------------------------------------------------
    # 核心设置（使用 settings 属性替代旧的 userEmail/userName 等顶层属性）
    # --------------------------------------------------------------------------
    settings = {
      # ---- 用户身份 ----
      # 这些信息会出现在每次 commit 的作者（Author）字段中
      user.name = "claudia";
      user.email = "3453289292@qq.com";

      # ---- 核心行为 ----
      init.defaultBranch = "main";                 # git init 时的默认分支名
      pull.rebase = true;                          # git pull 默认使用 rebase 而非 merge
      core.autocrlf = "input";                     # 提交时 CRLF → LF（跨平台协作友好）
      color.ui = true;                             # 开启彩色输出

      # ---- 命令别名 ----
      alias.st = "status";                         # git st → git status
      alias.ci = "commit";                         # git ci → git commit
      alias.co = "checkout";                       # git co → git checkout
      alias.br = "branch";                         # git br → git branch
      alias.lg = "log --oneline --graph --all --decorate";  # git lg → 美化日志
      alias.unstage = "reset HEAD --";             # git unstage → 取消暂存
      alias.last = "log -1 HEAD";                  # git last → 查看最后一次提交
    };

    # ---- 全局忽略规则 ----
    # 以下文件/目录被全局忽略（对所有仓库生效）
    ignores = [
      ".DS_Store"                                  # macOS 目录元数据
      "*.swp"                                      # Vim 交换文件
      "*.swo"                                      # Vim 交换文件（旧）
      "*~"                                         # 编辑器备份文件
      ".direnv/"                                   # direnv 缓存
      "result"                                     # nix build 结果符号链接
      ".envrc"                                     # direnv 配置（通常包含路径）
    ];
  };
}
