{
  description = "HeitorAugustoLN's personal wallpapers Nix flake.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    lib = nixpkgs.lib;

    supportedSystems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    forAllSystems = function: lib.genAttrs supportedSystems (system: function nixpkgs.legacyPackages.${system});

    # removeSuffixes :: String -> String -> String
    #
    # Remove a list of suffixes from a string
    # Return a string
    #
    # Example: [".png" ".jpg"] "./wallpapers/foo/bar.png" -> "./wallpapers/foo/bar"
    removeSuffixes = suffixes: str: builtins.foldl' (str: suffix: lib.strings.removeSuffix suffix str) str suffixes;

    # hasSuffixes :: [String] -> String -> Bool
    #
    # Check if a string has any of the suffixes
    # Return a boolean
    #
    # Example: [".png" ".jpg"] "./wallpapers/foo/bar.png" -> true
    hasSuffixes = suffixes: str: builtins.any (suffix: lib.strings.hasSuffix suffix str) suffixes;

    # isWallpaper :: [String] -> [String]
    #
    # Filter all files that have a specific set of suffixes
    # Return a list of relative paths in the form of strings
    #
    # Example: ["./wallpapers/foo/bar.png" "./wallpapers/README.md"] -> ["./wallpapers/foo/bar.png"]
    isWallpaper = paths: builtins.filter (path: hasSuffixes [".png" ".jpg" ".jpeg"] path) paths;

    # ls :: Path -> [String]
    #
    # List all files recursively in a directory
    # Return a list of relative paths in the form of strings
    #
    # Example: ls ./wallpapers -> ["./wallpapers/foo/bar.png" "./wallpapers/baz.png"]
    ls = dir: let
      absolutePath = lib.filesystem.listFilesRecursive dir;
    in
      map (path: lib.strings.replaceStrings [(toString dir)] [""] (toString path)) absolutePath;

    # generateWallpapersList :: [String] -> [AttrSet]
    #
    # Generate nested wallpaper attribute sets with recursion
    # Return a list of attribute sets
    #
    # Example: ["desktop" "foo" "bar"] -> [{ desktop = { foo = { bar = ./wallpapers/foo/bar.png; }; }; }]
    generateWallpapersList = paths:
      map (path: let
        pathNoExt = removeSuffixes [".png" ".jpg" ".jpeg"] path;
        splitPath = builtins.filter (str: str != "") (lib.strings.splitString "/" pathNoExt);
        generateNestedAttrSet = parts: value:
          if builtins.length parts == 1
          then {"${builtins.head parts}" = value;}
          else {"${builtins.head parts}" = generateNestedAttrSet (builtins.tail parts) value;};
      in
        generateNestedAttrSet splitPath (./wallpapers + path))
      paths;

    # wallpaperList :: [AttrSet] -> AttrSet
    #
    # Remove attribute sets from list and merge them into a single one
    # Return a single attribute set
    #
    # Example: [{ desktop = { foo = { bar = ./wallpapers/foo/bar.png; }; }; }] -> { desktop = { foo = { bar = ./wallpapers/foo/bar.png; }; }; }
    buildWallpaperExports = wallpaperList:
      builtins.foldl' (x: y: lib.recursiveUpdate x y) {} wallpaperList;

    attrsets = buildWallpaperExports (generateWallpapersList (isWallpaper (ls ./wallpapers)));
  in {
    formatter = forAllSystems (pkgs: pkgs.alejandra);

    inherit (attrsets) desktop;
  };
}
