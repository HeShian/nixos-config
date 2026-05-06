{
  description = "❄️ Westwood —— 模块化 NixOS + Home Manager 配置";

  # ============================================================================
  # 输入（inputs）：声明所有外部依赖
  # ============================================================================
  inputs = {
    # Nixpkgs 稳定频道 —— 保证系统基础包的稳定性
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager —— 用户级环境管理，跟随 nixpkgs 版本
    # CookNixvim —— 基于 Nixvim 的模块化 Neovim 配置
    CookNixvim = {
      url = "github:Youthdreamer/CookNixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # ============================================================================
  # 输出（outputs）：定义本 Flake 所有可构建的目标
  # ============================================================================
  outputs = { self, nixpkgs, home-manager, ... }@inputs:
  let
    # 系统架构 —— 当前为 x86_64 Linux
    system = "x86_64-linux";

    # 当前系统的 Nixpkgs 实例（包含允许非自由软件等全局配置）
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [ (import ./overlays/default.nix) ];
    };
  in {
    # --------------------------------------------------------------------------
    # NixOS 系统配置 —— 主机：westwood
    #   Home Manager 作为 NixOS 模块集成，sudo nixos-rebuild 时一起构建
    # --------------------------------------------------------------------------
    nixosConfigurations.westwood = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };

      modules = [
        # 平台架构（替代已弃用的 system 参数）
        { nixpkgs.hostPlatform = system; }
        { nixpkgs.overlays = [ (import ./overlays/default.nix) ]; }

        # 本机系统配置（由 configuration.nix 统一 import 所有子模块）
        #   子模块：networking / locale / hardware / desktop / packages
        ./hosts/westwood/configuration.nix

        # 跨主机共享的通用模块（镜像源、用户定义、安全设置等）
        ./modules/common.nix

        # ---- Home Manager 集成 ----

        home-manager.nixosModules.home-manager
        {
          # 使用系统全局的 pkgs（避免重复编译）
          home-manager.useGlobalPkgs = true;
          # 允许用户安装系统级别的包（如通过 home.packages）
          home-manager.useUserPackages = true;
          # 将 flake inputs 注入 Home Manager 模块
          home-manager.extraSpecialArgs = { inherit inputs; };
          # 用户 claudia 的 Home Manager 配置
          home-manager.users.claudia = import ./home/claudia;

        }
      ];
    };

    # --------------------------------------------------------------------------
    # 独立 Home Manager 配置（可选）
    #   在非 NixOS 系统上，或单独测试用户配置时使用
    #   用法：home-manager switch --flake .#claudia
    # --------------------------------------------------------------------------
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
