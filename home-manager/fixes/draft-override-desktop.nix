# from: https://old.reddit.com/r/NixOS/comments/scf0ui/how_would_i_update_desktop_file/jpmhb6s/
# just saving here in case it comes in handy in the future

# {config, pkgs, ...}:
# with pkgs; let
#   patchDesktop = pkg: appName: from: to: (lib.hiPrio (runCommand "$patched-desktop-entry-for-${appName}" {} ''
#   ${coreutils}/bin/mkdir -p $out/share/applications
#   ${gnused}/bin/sed 's#${from}#${to}#g' < ${pkg}/share/applications/${appName}.desktop > $out/share/applications/${appName}.desktop ''));
# in {
#   home.packages = [
#     keepassxc
#     (patchDesktop keepassxc "org.keepassxc.KeePassXC" "^Exec=keepassxc" "Exec=env QT_AUTO_SCREEN_SCALE_FACTOR=1 QT_SCREEN_SCALE_FACTORS=2 keepassxc")
#   ];