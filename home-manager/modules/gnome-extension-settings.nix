{
  lib,
  pkgs,
  config,
  home,
  ...
}: let
  cfg = config.gnomeExtensionSettings;
in {
  options.gnomeExtensionSettings = {
    enable = lib.mkEnableOption "manage GNOME extensions and settings";
    extensionsAndSettings = lib.mkOption {
      # TODO refine type/definition to show attrs (package, settings, dconfPath)
      type = with lib.types; (listOf (either package (attrsOf anything)));
      default = [];
      # example = ...;
      description = "List of GNOME extensions and settings to manage. Each entry is a package or an attribute set `package` attr and optionally `settings`, `dconfPath` attrs.";
    };
  };

  config = lib.mkIf cfg.enable (
    let
      packageToName = package: builtins.replaceStrings ["gnome-shell-extension-"] [""] package.pname;
      baseDconfPath = "org/gnome/shell/extensions/";
      cleanedSettings = with builtins;
        map (attrSetElem:
          {
            package = attrSetElem.package;
            settings = attrSetElem.settings;
          }
          // (
            if attrSetElem ? dconfPath
            then {dconfPath = attrSetElem.dconfPath;}
            else {dconfPath = packageToName attrSetElem.package;}
          ))
        (filter (elem: ((typeOf elem) == "set") && elem ? settings) cfg.extensionsAndSettings);
      extensionSettingsDconf = with builtins;
        listToAttrs (map (attrSetElem: {
            name = baseDconfPath + attrSetElem.dconfPath;
            value = attrSetElem.settings;
          })
          cleanedSettings);
      extensions = with builtins;
        (filter (elem: (lib.isDerivation elem)) cfg.extensionsAndSettings)
        ++ map (attrSetElem:
          if (attrSetElem ? package)
          then attrSetElem.package
          else throw "attrSetElem of extensionsAndSettings must have a `package` attr")
        (filter (elem: !(lib.isDerivation elem)) cfg.extensionsAndSettings);
      enabledExtensionDconf = {
        "org/gnome/shell" = {
          enabled-extensions = builtins.map (extension: extension.extensionUuid) extensions;
        };
      };
    in {
      home.packages = extensions;
      # dconf.settings = lib.debug.traceValSeq (extensionSettingsDconf // enabledExtensionDconf);
      dconf.settings = extensionSettingsDconf // enabledExtensionDconf;
    }
  );
}
