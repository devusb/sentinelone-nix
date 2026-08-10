{
  lib,
  pkgs,
  nixosModules,
}:
let
  defaultTestAttrs = {
    imports = [
      nixosModules.default
      "${pkgs.path}/nixos/tests/common/user-account.nix"
    ];
    users.users.alice.extraGroups = [ "wheel" ];
    security.sudo.wheelNeedsPassword = false;
    services.sentinelone = {
      enable = true;
      # base64 encoded config with fake site key
      sentinelOneManagementTokenPath = pkgs.writeText "s1_token" "eyJ1cmwiOiAiaHR0cHM6Ly9zZW50aW5lbG9uZS1wcm9ncmFtLnNlbnRpbmVsb25lLm5ldCIsICJz
aXRlX2tleSI6ICJmM2M4N2IyZTlhMWQ0YzZlIn0KCg==";
    };
  };
in
pkgs.nixosTest {
  name = "sentinelone";
  nodes = {
    withoutCustomerId = defaultTestAttrs;

    withCustomerId = lib.recursiveUpdate defaultTestAttrs {
      services.sentinelone.customerId = "goon@goon.ventures-42069B00B5";
    };

    withDepracatedOptions = lib.recursiveUpdate defaultTestAttrs {
      services.sentinelone = {
        email = "goon@goon.ventures";
        serialNumber = "42069B00B5";
      };
    };
  };

  testScript = ''
    start_all()

    withoutCustomerId.wait_for_unit("sentinelone.service")
    withoutCustomerId.succeed("mountpoint -q /opt/sentinelone")
    withoutCustomerId.succeed("touch /opt/sentinelone/lib/.write-test && rm /opt/sentinelone/lib/.write-test")
    withoutCustomerId.fail("touch /opt/sentinelone/bin/.write-test")
    withoutCustomerId.fail("grep -q sentinelone /etc/fstab")
    withoutCustomerId.fail("journalctl -b --grep='ordering cycle' --quiet")

    withCustomerId.wait_for_unit("sentinelone.service")

    withDepracatedOptions.wait_for_unit("sentinelone.service")
  '';
}
