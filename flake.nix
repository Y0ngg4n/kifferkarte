{
  description = "moxplatform";
  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/23.11";
    flake-utils.url = "github:numtide/flake-utils";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs";
  };
  outputs = { self, nixpkgs, flake-utils, android-nixpkgs }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs {
      inherit system;
      config = {
        android_sdk.accept_license = true;
        allowUnfree = true;
      };
    };
    # Everything to make Flutter happy
    sdk = android-nixpkgs.sdk.${system} (sdkPkgs: with sdkPkgs; [
      cmdline-tools-latest
      build-tools-30-0-3
      build-tools-33-0-2
      build-tools-34-0-0
      platform-tools
      emulator
#      patcher-v4
      platforms-android-30
      platforms-android-31
      platforms-android-33
    ]);
    pinnedJDK = pkgs.jdk17;
  in {
    devShell = pkgs.mkShell {
      buildInputs = with pkgs; [
        # Android
        pinnedJDK
        sdk
        # Flutter
        flutter 
        dart
        # Code hygiene
        gitlint
        # Flutter dependencies for linux desktop
        atk
        cairo
        clang
        cmake
        epoxy
        gdk-pixbuf
        glib
        gtk3
        harfbuzz
        ninja
        pango
        pcre
        pkg-config
        xorg.libX11
        xorg.xorgproto
      ];

      # Make Flutter build on desktop
      #CPATH = "${pkgs.xorg.libX11.dev}/include:${pkgs.xorg.xorgproto}/include";
      # LD_LIBRARY_PATH = with pkgs; lib.makeLibraryPath [ atk cairo epoxy gdk-pixbuf glib gtk3 harfbuzz pango ];
      
      ANDROID_HOME = "${sdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${sdk}/share/android-sdk";
      JAVA_HOME = pinnedJDK;

      # Fix an issue with Flutter using an older version of aapt2, which does not know
      # an used parameter.
      GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${sdk}/share/android-sdk/build-tools/34.0.0/aapt2";
    };
  });
}
