{
  # ===========================================================================
  # Flake 描述
  #   这是一个简短的元数据字符串，flake 命令和工具会显示此信息。
  # ===========================================================================
  description = "❄️ Westwood —— 模块化 NixOS + Home Manager 配置";

  # ===========================================================================
  # 输入（inputs）
  #
  #   声明所有外部依赖。每个 input 可以是一个 GitHub 仓库、本地路径、
  #   或其他 flake。inputs 之间的依赖关系通过 follows 机制管理：
  #   follows = "nixpkgs" 表示使用根 flake 的 nixpkgs，避免重复锁定。
  #
  #   输入列表：
  #   - nixpkgs:          Nix 包集合（unstable 频道）
  #   - home-manager:     用户级环境管理（跟随 nixpkgs 版本）
  #   - CookNixvim:       基于 Nixvim 的模块化 Neovim 配置（跟随 nixpkgs）
  # ===========================================================================
  inputs = {
    # Nixpkgs（unstable 频道）
    # 提供 NixOS 系统包和模块的最新版本
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager —— 用户级环境管理
    #   通过 follows 跟随顶层 nixpkgs，避免锁定两个不同版本的 nixpkgs
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # CookNixvim —— 模块化 Neovim 配置
    #   独立仓库，提供预配置的 Neovim 发行版
    #   同样跟随顶层 nixpkgs，确保包版本兼容
    CookNixvim = {
      url = "github:Youthdreamer/CookNixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # ===========================================================================
  # 输出（outputs）
  #
  #   定义本 Flake 所有可构建的目标：
  #   1. nixosConfigurations.westwood  → NixOS 系统配置
  #      用 sudo nixos-rebuild switch --flake .#westwood 部署
  #   2. homeConfigurations.claudia    → 独立 Home Manager 配置
  #      用 home-manager switch --flake .#claudia 部署（非 NixOS 系统用）
  #
  #   system = "x86_64-linux"：当前主机架构
  # ===========================================================================
  outputs = { self, nixpkgs, home-manager, ... }@inputs:
  let
    # 系统架构 —— 当前为 x86_64 Linux
    system = "x86_64-linux";

    # 创建一个预配置的 pkgs 实例
    # 包含：允许非自由软件、注入自定义 overlay（openldap 修补 + 自定义包）
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [ (import ./overlays/default.nix) ];
    };
  in {
    # -------------------------------------------------------------------------
    # NixOS 系统配置 —— 主机：westwood
    #
    #   使用 nixosSystem 构建完整的 NixOS 系统。
    #   Home Manager 作为 NixOS 模块集成在内，使用 sudo nixos-rebuild 时
    #   系统配置和用户配置会一起构建和部署。
    #
    #   模块加载顺序：
    #     1. nixpkgs.hostPlatform + nixpkgs.overlays（基础设置）
    #     2. hosts/westwood/configuration.nix（主机所有子模块）
    #     3. modules/common.nix（共享模块：镜像、用户、GC、安全）
    #     4. home-manager NixOS 模块（Home Manager 集成）
    # -------------------------------------------------------------------------
    nixosConfigurations.westwood = nixpkgs.lib.nixosSystem {
      # 将 flake inputs（如 CookNixvim）传递到所有 NixOS 模块中
      specialArgs = { inherit inputs; };

      modules = [
        # ---- 基础设置 ----
        { nixpkgs.hostPlatform = system; }
        { nixpkgs.overlays = [ (import ./overlays/default.nix) ]; }

        # ---- 主机配置（configuration.nix imports 所有子模块） ----
        #   子模块清单：networking / locale / hardware / desktop / packages / flatpak
        ./hosts/westwood/configuration.nix

        # ---- 共享模块 ----
        #   镜像源加速、用户定义、Nix GC、sudo 免密、非自由软件许可
        ./modules/common.nix

        # ---- Home Manager 集成（作为 NixOS 模块） ----
        home-manager.nixosModules.home-manager
        {
          # 使用系统全局的 pkgs（避免为 home-manager 重复编译 nixpkgs）
          home-manager.useGlobalPkgs = true;
          # 允许用户级安装系统包（如 home.packages）
          home-manager.useUserPackages = true;
          # 将 flake inputs 注入 Home Manager 模块（CookNixvim 等可用）
          home-manager.extraSpecialArgs = { inherit inputs; };
          # 用户 claudia 的 Home Manager 配置入口
          home-manager.users.claudia = import ./home/claudia;
        }
      ];
    };

    # -------------------------------------------------------------------------
    # 独立 Home Manager 配置（可选）
    #
    #   此配置在以下场景使用：
 	#   - 在非 NixOS 系统上部署相同的用户环境
    #   - 单独测试用户配置而不重建系统
    #
    #   用法：home-manager switch --flake .#claudia
    #   注意：在 NixOS 系统上，建议使用 nixos-rebuild（包含 home-manager），
    #   因为独立模式可能会与系统配置冲突。
    # -------------------------------------------------------------------------
    homeConfigurations.claudia = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ (import ./overlays/default.nix) ];
      };

      extraSpecialArgs = { inherit inputs; };

      modules = [
        ./home/claudia
      ];
    };
  };
}
