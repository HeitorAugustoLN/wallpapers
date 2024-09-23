{
  description = "HeitorAugustoLN's personal wallpapers Nix flake.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs:
    let
      lib = inputs.nixpkgs.lib;

      supportedSystems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems =
        function: lib.genAttrs supportedSystems (system: function inputs.nixpkgs.legacyPackages.${system});

      # removeSuffixes :: [String] -> String -> String
      #
      # Remove a list of suffixes from a string. If the string has any of the suffixes, it will be removed.
      #
      # Example: removeSuffixes [ ".png" ".jpg" ] "wallpaper.png" -> "wallpaper"
      removeSuffixes =
        suffixes: str: builtins.foldl' (str: suffix: lib.strings.removeSuffix suffix str) str suffixes;

      # hasSuffixes :: [String] -> String -> Bool
      #
      # Check if a string has any of the suffixes.
      #
      # Example: hasSuffixes [ ".png" ".jpg" ] "wallpaper.png" -> true
      hasSuffixes = suffixes: str: builtins.any (suffix: lib.strings.hasSuffix suffix str) suffixes;

      # isWallpaper :: [String] -> [String]
      #
      # Filter a list of paths to only keep the ones that have a image extension.
      #
      # Example: isWallpaper [ "wallpaper.png" "text.txt" ] -> [ "wallpaper.png" ]
      isWallpaper =
        paths:
        builtins.filter (
          path:
          hasSuffixes [
            ".png"
            ".jpg"
            ".jpeg"
          ] path
        ) paths;

      # ls :: Path -> [String]
      #
      # List all files recursively in a directory.
      # The paths are relative to the directory.
      #
      # Example: ls ./wallpapers -> [ "/wallpaper.png" ]
      ls =
        dir:
        let
          absolutePath = lib.filesystem.listFilesRecursive dir;
        in
        map (path: lib.strings.replaceStrings [ (toString dir) ] [ "" ] (toString path)) absolutePath;

      # generateWallpapersList :: [String] -> [AttrSet]
      #
      # Generate a list of attribute sets from a list of paths.
      # The attribute sets are nested based on the path structure.
      #
      # Example: generateWallpapersList [ "/wallpaper.png" ] -> [ { wallpaper = ./wallpapers/wallpaper.png; } ]
      generateWallpapersList =
        paths:
        map (
          path:
          let
            pathNoExt = removeSuffixes [
              ".png"
              ".jpg"
              ".jpeg"
            ] path;
            splitPath = builtins.filter (str: str != "") (lib.strings.splitString "/" pathNoExt);
            generateNestedAttrSet =
              parts: value:
              if builtins.length parts == 1 then
                { "${builtins.head parts}" = value; }
              else
                { "${builtins.head parts}" = generateNestedAttrSet (builtins.tail parts) value; };
          in
          generateNestedAttrSet splitPath (./wallpapers + path)
        ) paths;

      # buildWallpaperExports :: [AttrSet] -> AttrSet
      #
      # Build a single attribute set from a list of attribute sets.
      #
      # Example: buildWallpaperExports [ { wallpaper = ./wallpapers/wallpaper.png; } ] -> { wallpaper = ./wallpapers/wallpaper.png; }
      buildWallpaperExports =
        wallpaperList: builtins.foldl' (x: y: lib.recursiveUpdate x y) { } wallpaperList;

      attrsets = buildWallpaperExports (generateWallpapersList (isWallpaper (ls ./wallpapers)));
    in
    {
      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);

      inherit (attrsets) desktop;
    };
}
