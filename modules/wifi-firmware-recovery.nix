# Recover from the AX211 firmware crash that leaves the machine with no network.
#
# Measured on this machine (HONOR MagicBook 14 2026, JGC-N / M1070, Core Ultra
# X7 358H, Wi-Fi 6E AX211 at 0000:00:14.3 -- a CNVi0 device sharing its RF with
# Bluetooth):
#
#   5 of the last 6 boots brought up no wireless interface at all. The driver
#   loads the firmware, then ~2s later the firmware dies:
#
#     iwlwifi 0000:00:14.3: SecBoot CPU1 Status: 0xf804, CPU2 Status: 0xb03
#     iwlwifi 0000:00:14.3: UMAC CURRENT PC: 0xd05c18 / LMAC1 CURRENT PC: 0xd05c20
#     iwlwifi 0000:00:14.3: Start IWL Error Log Dump:
#     iwlwifi 0000:00:14.3: 0x00000092 | ADVANCED_SYSASSERT
#     iwlwifi 0000:00:14.3: 0x20000070 | NMI_INTERRUPT_LMAC_FATAL
#
#   and on one boot a different signature entirely, which makes this a firmware
#   bug rather than a fixed sequence of events:
#
#     iwlwifi 0000:00:14.3: 0x00000034 | NMI_INTERRUPT_WDG
#     iwlwifi 0000:00:14.3: 0x40002120 | error ID
#     iwlwifi 0000:00:14.3: 0x00000B03 | IML/ROM error/state
#     iwlwifi 0000:00:14.3: 0x00000040 | FSEQ_ERROR_CODE
#
#   Consequence: `wlp0s20f3: renamed from wlan0` never appears, so there is no
#   netdev, NetworkManager has nothing to activate, wpa_supplicant logs "Failed
#   to initialize driver interface", and GNOME Settings shows no Wi-Fi at all.
#   That wpa_supplicant line is the symptom, not the cause.
#
#   The kernel (7.2.6) and the firmware (100.dc7aa42e.0) were byte-identical
#   across all six boots, five of which failed. So this is not a version problem,
#   and swapping kernels is not a fix.
#
# Why there is no firmware update to wait for: this signature is reported
# upstream for AX211/CNVi0 generally -- Launchpad #1962515 dumps
# IML/ROM error/state 0x00000B03 and SecBoot CPU2 Status 0xb03, matching ours
# field for field -- and upstream's own conclusion is "this can only be fixed in
# the firmware". HONOR publishes no update for this machine either: their only
# documented paths are the Windows PC Manager and a Windows BIOS_1.xx.exe, and
# they do not publish to LVFS, so fwupd has nothing to offer. This BIOS is 1.04
# (2026-04-07), which is the version the 358H model shipped with and the newest
# publicly reported.
#
# So the only thing left is to reload the driver when the interface is missing.
# That is a mitigation, not a cure, and it is written as one: it cannot fix a
# firmware bug, it only gives the hardware a second chance to initialise.
{ config, lib, pkgs, ... }:

{
  # Note the interface name is deliberately not hardcoded to wlp0s20f3. That is
  # what udev assigned here, but a driver or firmware bump can rename it, and a
  # hardcoded name would then report a perfectly healthy adapter as missing --
  # and "recover" it, which would tear down working Wi-Fi. The check below
  # matches any wireless netdev instead.
  systemd.services.wifi-firmware-recovery = {
    description = "Reload iwlwifi when the AX211 firmware crashed and no interface exists";

    # A boot-time oneshot, not a timer. The failure is decided within seconds of
    # the firmware loading and nothing recovers it on its own afterwards, so a
    # periodic check would only re-run a race that has already been lost.
    wantedBy = [ "multi-user.target" ];

    # After udev has had its chance to name the interface, and after
    # NetworkManager has already tried (and failed) to bring it up -- otherwise
    # this races the normal path and can "recover" an adapter that was about to
    # come up on its own.
    after = [ "systemd-udevd.service" "NetworkManager.service" ];

    path = [
      pkgs.kmod
      pkgs.coreutils
    ];

    # Let the firmware finish loading and die. Measured crash point is ~2s after
    # the driver announces the firmware, and NetworkManager's own retries extend
    # past that; 25s is comfortably after both without holding up the boot.
    serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/sleep 25";

    script = ''
      # Wired interfaces do not count as "the network is fine" -- this machine
      # is a laptop on Wi-Fi, and the failure mode being covered is specifically
      # "no wireless netdev came up".
      have_wireless() {
        local p
        for p in /sys/class/net/*/wireless; do
          [ -e "$p" ] && return 0
        done
        return 1
      }

      if have_wireless; then
        echo "wireless interface present, nothing to do"
        exit 0
      fi

      echo "no wireless interface found -- assuming the iwlwifi firmware crashed"
      dmesg | grep -iE 'ADVANCED_SYSASSERT|FSEQ_ERROR_CODE|NMI_INTERRUPT' | tail -20 || true

      # Three attempts, because a crashed CNVi0 device sometimes needs the bus
      # to settle before a reload sticks. Upstream's only manual workaround for
      # this class of crash is remove-and-reinsert with a pause, so the pause is
      # part of the fix rather than politeness.
      attempt=1
      while [ "$attempt" -le 3 ]; do
        echo "attempt $attempt: reloading iwlwifi"
        modprobe -r iwlwifi || echo "  modprobe -r returned $? (the module may already be gone)"
        sleep 3
        modprobe iwlwifi || echo "  modprobe returned $?"

        n=0
        while [ "$n" -lt 10 ]; do
          if have_wireless; then
            echo "attempt $attempt: interface is back after ''${n}s"
            # NetworkManager saw the device disappear; make it look again rather
            # than waiting out its own retry schedule.
            systemctl try-restart NetworkManager.service || true
            exit 0
          fi
          sleep 1
          n=$(( n + 1 ))
        done

        attempt=$(( attempt + 1 ))
        [ "$attempt" -le 3 ] && sleep 5
      done

      # Exit 0 deliberately. A failed unit here means "no network", and marking
      # the boot as degraded would add a second problem on top of the first --
      # but the message has to be impossible to miss, because at this point the
      # machine is offline and has no remote remedy.
      echo "RECOVERY FAILED: no wireless interface after 3 reload attempts."
      echo "This machine now has no network. Fix it by hand with:"
      echo "  sudo modprobe -r iwlwifi; sudo modprobe iwlwifi"
      echo "  rfkill unblock wifi        # only if the adapter is soft-blocked"
      echo "  sudo systemctl restart NetworkManager"
      echo "and if that does not help, reboot: sudo systemctl reboot"
      echo "There is no network path to fall back on, which is why reboot is the"
      echo "last resort rather than the first suggestion."
      exit 0
    '';
  };
}