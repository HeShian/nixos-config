{ lib
, fetchFromGitHub
, rustPlatform
, pkg-config
, openssl
}:

rustPlatform.buildRustPackage rec {
  pname = "bilibili-tui";
  version = "1.0.11";

  src = fetchFromGitHub {
    owner = "MareDevi";
    repo = "bilibili-tui";
    rev = "v${version}";
    hash = "sha256-QHggUJKxZTex5pb/xtolBYbZLr7ozoSIlXlVPDu+WhI=";
  };

  cargoHash = "sha256-ABL2qo8XUVxqeRESlAhLxwxrzo0rd8vaesHFFmhdBk0=";
  doCheck = false;

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ openssl ];

  meta = {
    description = "A terminal user interface (TUI) client for Bilibili";
    homepage = "https://github.com/MareDevi/bilibili-tui";
    license = lib.licenses.mit;
    mainProgram = "bilibili-tui";
  };
}
