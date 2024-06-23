{
  description = "A very simple flake that exports my wallpapers";
  outputs = {self}: {
    abstract = {
      catppuccin = {
        topography = ./wallpapers/abstract/theme/catppuccin/topography.jpg;
      };
    };
  };
}