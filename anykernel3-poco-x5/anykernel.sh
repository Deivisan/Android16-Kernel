### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers
## Modified for POCO X5 5G (moonstone/rose) - Docker/LXC/NetHunter Kernel

### AnyKernel setup
# global properties
properties() { '
kernel.string=Docker-LXC-NetHunter Kernel for POCO X5 5G by DevSan
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
supported.versions=13-14
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
ui_print "  Docker/LXC/NetHunter Custom Kernel";
ui_print "  for POCO X5 5G (moonstone/rose)";
ui_print "========================================";
ui_print " ";
ui_print "Features enabled:";
ui_print "  - Docker & LXC support";
ui_print "  - Kali NetHunter compatible";
ui_print "  - Overlay filesystem";
ui_print "  - Full cgroups & namespaces";
ui_print " ";
ui_print "Installing kernel...";
ui_print " ";

flash_boot;
## end boot install
