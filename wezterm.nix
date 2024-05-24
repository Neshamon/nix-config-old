{ stdenv, lib, fetchFromGitHub, ncurses, perl, pkg-config, python3
, installShellFiles, openssl, libGL, libX11, libxcb, libxkbcommon, xcbutil
, xcbutilimage, xcbutilkeysyms, xcbutilwm, wayland, zlib, nixosTests, runCommand
, vulkan-loader, rustPlatform, fontconfig, inputs }:

rustPlatform.buildRustPackage rec {
  pname = "wezterm-src";
  version = inputs.wezterm-git.shortRev;

  src = inputs.wezterm-git;

  postPatch = ''
    echo ${version} > .tag
    rm -r wezterm-ssh/tests
  '';

  cargoLock = {
    lockFile = "${inputs.wezterm-git}/Cargo.lock";
    outputHashes = {
      "xcb-imdkit-0.3.0" = "sha256-77KaJO+QJWy3tJ9AF1TXKaQHpoVOfGIRqteyqpQaSWo=";
      "sqlite-cache-0.1.3" = "sha256-sBAC8MsQZgH+dcWpoxzq9iw5078vwzCijgyQnMOWIkk=";
    };
  };

  nativeBuildInputs = [ installShellFiles ncurses pkg-config python3 ];

  buildInputs = [
    fontconfig
    zlib
  ] ++ lib.optionals stdenv.isLinux [
    libX11
    libxcb
    libxkbcommon
    openssl
    wayland
    xcbutil
    xcbutilimage
    xcbutilkeysyms
    xcbutilwm
  ];

  buildFeatures = [ "distro-defaults" ];

  postInstall = ''
    mkdir -p $out/nix-support
        echo "${passthru.terminfo}" >> $out/nix-support/propagated-user-env-packages

        install -Dm644 assets/icon/terminal.png $out/share/icons/hicolor/128x128/apps/org.wezfurlong.wezterm.png
        install -Dm644 assets/wezterm.desktop $out/share/applications/org.wezfurlong.wezterm.desktop
        install -Dm644 assets/wezterm.appdata.xml $out/share/metainfo/org.wezfurlong.wezterm.appdata.xml

        install -Dm644 assets/shell-integration/wezterm.sh -t $out/etc/profile.d
        installShellCompletion --cmd wezterm \
          --bash assets/shell-completion/bash \
          --fish assets/shell-completion/fish \
          --zsh assets/shell-completion/zsh

        install -Dm644 assets/wezterm-nautilus.py -t $out/share/nautilus-python/extensions
  '';

  prefixup = lib.optionalString stdenv.isLinux ''
    patchelf \
    --add-needed "${libGL}/lib/libEGL.so.1" \
    --add-needed "${vulkan-loader}/lib/libvulkan.so.1" \
    $out/bin/wezterm-gui
  '';

  passthru = {
    tests = {
      all-terminfo = nixosTests.allTerminfo;
      terminal-emulators = nixosTests.terminal-emulators.wezterm;
    };

    terminfo =
      runCommand "wezterm-terminfo" { nativeBuildInputs = [ ncurses ]; } ''
        mkdir -p $out/share/terminfo $out/nix-support
        tic -x -o $out/share/terminfo ${src}/termwiz/data/wezterm.terminfo
      '';
  };

  meta = with lib; {
    description =
      "GPU-accelerated cross-platform terminal emulator and multiplexer written by @wez and implemented in Rust";
    homepage = "https://wezfurlong.org/wezterm";
    license = licenses.mit;
    mainProgram = "wezterm";
  };
}
