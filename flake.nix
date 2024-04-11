{
  description = "GUI fetch tool written in Flutter for Linux.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/b06025f1533a1e07b6db3e75151caa155d1c7eb3";
    flake-utils.url = "github:numtide/flake-utils";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs";
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      packages = rec {
        guifetch = pkgs.callPackage ./nix/package.nix {};
        default = guifetch;
      };
      devShell = let
        android-nixpkgs = pkgs.callPackage inputs.android-nixpkgs {};
        android-sdk = android-nixpkgs.sdk (sdkPkgs:
          with sdkPkgs; [
            cmdline-tools-latest
            build-tools-32-0-0
	    build-tools-33-0-2
            build-tools-34-0-0
            build-tools-30-0-3
            platform-tools
            platforms-android-28
	    platforms-android-30
            platforms-android-31
            platforms-android-32
            platforms-android-33
            platforms-android-34
            emulator
          ]);
      in
        pkgs.mkShell {
          # Fix an issue with Flutter using an older version of aapt2, which does not know
          # an used parameter.
          GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${android-sdk}/share/android-sdk/build-tools/34.0.0/aapt2";
          ANDROID_HOME = "${android-sdk}/share/android-sdk";
          ANDROID_SDK_ROOT = "${android-sdk}/share/android-sdk";

          nativeBuildInputs = with pkgs; [
            flutter
            pkg-config
          ];
          buildInputs = with pkgs; [
            jdk17
            android-sdk
          ];
        };
    })
    // {
      overlays.default = final: prev: {
        guifetch = prev.callPackage ./nix/package.nix {};
      };
      homeManagerModules.default = import ./nix/hm-module.nix self;
    };
}
