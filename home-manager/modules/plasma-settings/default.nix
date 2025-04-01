{
  lib,
  pkgs,
  config,
  secrets,
  ...
}: {
  # set user icon
  home.file.".face.icon".source = ../../../media/madeline.jpg;
}
