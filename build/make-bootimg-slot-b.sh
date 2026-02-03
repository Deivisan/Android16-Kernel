#!/usr/bin/env bash
set -euo pipefail

# Cria boot.img com kernel 5.4.302 para flash no slot B
# Requisitos: magiskboot instalado e backup de boot.img disponível

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KERNEL_IMG="$PROJECT_ROOT/kernel-moonstone-devs/arch/arm64/boot/Image.gz"
BACKUP_TAR="$PROJECT_ROOT/backups/poco-x5-5g-rose-2025-02-01/device-images-backup-2025-02-01.tar.xz"
WORKDIR="$PROJECT_ROOT/build/boot-work"
OUTDIR="$PROJECT_ROOT/build/out"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_BOOT="$OUTDIR/boot-b-5.4.302-$STAMP.img"

if ! command -v magiskboot >/dev/null 2>&1; then
  echo "ERRO: magiskboot não encontrado. Instale e rode novamente."
  echo "Sugestão: pacman/AUR (magiskboot) ou magisk (android-tools não inclui)."
  exit 2
fi

if [ ! -f "$KERNEL_IMG" ]; then
  echo "ERRO: Kernel não encontrado: $KERNEL_IMG"
  exit 3
fi

if [ ! -f "$BACKUP_TAR" ]; then
  echo "ERRO: Backup não encontrado: $BACKUP_TAR"
  exit 4
fi

mkdir -p "$WORKDIR" "$OUTDIR"
rm -rf "$WORKDIR"/*

echo "📦 Extraindo boot.img do backup..."
tar -xJf "$BACKUP_TAR" -C "$WORKDIR"

if [ ! -f "$WORKDIR/device-images/boot.img" ]; then
  echo "ERRO: boot.img não encontrado dentro do backup"
  exit 5
fi

cd "$WORKDIR"
echo "🔧 Unpack boot.img com magiskboot..."
magiskboot unpack "$WORKDIR/device-images/boot.img" >/dev/null

echo "🧩 Substituindo kernel..."
cp "$KERNEL_IMG" "$WORKDIR/kernel"

echo "📦 Repack boot.img..."
magiskboot repack "$WORKDIR/device-images/boot.img" "$OUT_BOOT" >/dev/null

echo "✅ Boot image gerado: $OUT_BOOT"
echo "➡️ Flash (slot B): fastboot flash boot_b \"$OUT_BOOT\""
echo "➡️ Ativar slot B: fastboot set_active b"
echo "➡️ Reboot: fastboot reboot"
