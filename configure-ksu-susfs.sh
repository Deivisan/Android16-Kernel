#!/bin/bash
set -e

cd kernel-moonstone-devs

# Enable KernelSU and SUSFS configurations
./scripts/config --enable CONFIG_KSU
./scripts/config --enable CONFIG_KSU_DEBUG
./scripts/config --enable CONFIG_KSU_SUSFS
./scripts/config --enable CONFIG_KSU_SUSFS_SUS_PATH
./scripts/config --enable CONFIG_KSU_SUSFS_SUS_MOUNT
./scripts/config --enable CONFIG_KSU_SUSFS_SUS_KSTAT
./scripts/config --enable CONFIG_KSU_SUSFS_SUS_MAPS
./scripts/config --enable CONFIG_KSU_SUSFS_SUS_PROC_FD_LINK
./scripts/config --enable CONFIG_KSU_SUSFS_SUS_MEMFD
./scripts/config --enable CONFIG_KSU_SUSFS_TRY_UMOUNT
./scripts/config --enable CONFIG_KSU_SUSFS_SPOOF_UNAME

# Enable required kernel features for Halium/LXC
./scripts/config --enable CONFIG_USER_NS
./scripts/config --enable CONFIG_CGROUP_DEVICE
./scripts/config --enable CONFIG_CGROUP_PIDS
./scripts/config --enable CONFIG_SYSVIPC
./scripts/config --enable CONFIG_POSIX_MQUEUE
./scripts/config --enable CONFIG_IKCONFIG_PROC
./scripts/config --enable CONFIG_SECURITY_APPARMOR
./scripts/config --set-str CONFIG_DEFAULT_SECURITY apparmor

# Set build environment
./scripts/config --enable CONFIG_MODULES
./scripts/config --enable CONFIG_MODULE_UNLOAD

echo "Configuration updated for KSU+SUSFS"