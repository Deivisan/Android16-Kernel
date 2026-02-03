 ### AnyKernel3 Ramdisk Mod Script
 ## osm0sis @ xda-developers
 ## Modified for POCO X5 5G (moonstone/rose) - KernelSU-Next v3.0.1 + SUSFS + Docker Kernel

 ### AnyKernel setup
 # global properties
 properties() { '
 kernel.string=KernelSU-Next v3.0.1 + SUSFS + Docker for POCO X5 5G by DevSan
 do.devicecheck=1
 do.modules=0
 do.systemless=1
 do.cleanup=1
 do.cleanuponabort=0
 device.name1=moonstone
 device.name2=rose
 device.name3=
 device.name4=
 device.name5=
 supported.versions=13-16
 supported.patchlevels=
 supported.vendorpatchlevels=
 '; } # end properties


### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# boot shell variables
BLOCK=auto;
IS_SLOT_DEVICE=1;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# boot install
split_boot; # skip ramdisk unpack since we're only replacing kernel

 # Custom kernel message
 ui_print " ";
 ui_print "========================================";
  ui_print "  KernelSU-Next v3.0.1 + SUSFS + Docker";
  ui_print "  for POCO X5 5G (moonstone/rose)";
 ui_print "========================================";
 ui_print " ";
  ui_print "Features enabled:";
  ui_print "  - KernelSU v3.0.1 root access";
  ui_print "  - Full SUSFS systemless root";
  ui_print "  - Path hiding & mount spoofing";
  ui_print "  - Docker/LXC container support";
  ui_print "  - DTBO overlay for hardware compatibility";
  ui_print "  - KernelSU Manager compatible";
 ui_print " ";
 ui_print "Installing kernel...";
 ui_print " ";

flash_boot;
## end boot install
