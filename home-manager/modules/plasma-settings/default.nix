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

  # try to fix https://bugs.kde.org/show_bug.cgi?id=488860 also (in case putting it in environment.sessionVariables didn't work)
  # (https://reddit.com/r/kde/comments/1dkhfvl/is_it_only_me_or_has_anyone_elses_desktop/l9sihtq/)
  programs.bash.bashrcExtra = ''
    export KWIN_DRM_DISABLE_TRIPLE_BUFFERING=1
  '';

  systemd.user.services.kill-firefox = {
    Unit = {
      Description = "Kill Firefox on session stop";
      Before = ["exit.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.procps}/bin/pkill -f firefox";
      RemainAfterExit = "yes";
    };
    Install = {WantedBy = ["exit.target"];};
  };
}
