#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"

# Имя Tcl‑скрипта сборки
BLD_SCRIPT="xbld.tcl"

# Каталог для логов
LOG_DIR="log"

# Удаляем старые директории Vivado и логов
rm -rf ./.Xil || true
rm -rf "./$LOG_DIR" || true

# Создаём чистую папку для логов
mkdir -p "$LOG_DIR"

# Запуск Vivado в batch‑режиме
vivado -mode batch          \
       -journal "$LOG_DIR/bld.jou" \
       -log     "$LOG_DIR/bld.log" \
       -source  "$BLD_SCRIPT"      \
       -notrace