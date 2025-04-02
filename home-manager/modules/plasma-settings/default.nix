{
  lib,
  pkgs,
  config,
  secrets,
  ...
}: {
  # set user icon
  # it seems like that in order for this to work, you need ~ permissions at least 711, and also
  # to delete /var/lib/AccountsService/users/$USER and /var/lib/AccountsService/icons/$USER
  home.file.".face.icon".source = ../../../media/madeline.jpg;
}
