{ config, pkgs, ... }:

# ==============================================================================
# Git 版本控制配置
# ==============================================================================

{
  programs.git = {
    enable = true;

    # ---- 用户信息与核心设置（迁移至 settings 属性） ----
    settings = {
      user.name = "claudia";
      user.email = "3453289292@qq.com";

      init.defaultBranch = "main";             # 默认分支名
      pull.rebase = true;                      # pull 时使用 rebase 而非 merge
      core.autocrlf = "input";                 # 统一 LF 换行符
      color.ui = true;                         # 开启颜色输出

      # ---- 别名 ----
      alias.st = "status";
      alias.ci = "commit";
      alias.co = "checkout";
      alias.br = "branch";
      alias.lg = "log --oneline --graph --all --decorate";
      alias.unstage = "reset HEAD --";
      alias.last = "log -1 HEAD";
    };

    # ---- 需要版本控制忽略的文件模式 ----
    ignores = [
      ".DS_Store"
      "*.swp"
      "*.swo"
      "*~"
      ".direnv/"
      "result"
      ".envrc"
    ];
  };
}
