#! /usr/bin/env bash

# Salir automaticamente cuando haya un error.
set -e

# vamos a usar esta imagen para correr el debugger.
IMG="data/imagenes_a_testear/NoCountryForOldMen.32x18.bmp"

# Ejecutable
TP2="../build/tp2"

# Source path con codigo filtros
SOURCE_DIR="../filters"

# FIXME hacelo parametro
FILTRO="Manchas"

# FIXME hacelo parametro
IMPL="asm"

OUTPUT_DIR="data/resultados_debugging"

# ----------------------------------------------------------------------------

# Corre make
echo -e "\n>>>>>>>>>> Corriendo Make"
cd ..
if ! make; then
    echo -e "\n>>>>>>>>>> FALLO Make"
    exit -1
fi
cd tests

# Se asegura que la imagen exista
if [[ ! -f "$IMG" ]]; then
    echo -e "\n>>>>>>>>>> Generando Imagenes"
    pwd
    ./1_generar_imagenes.py
fi

mkdir -p "$OUTPUT_DIR" # Hace directorio vacio para tirar la salida
rm -f    "$OUTPUT_DIR/*" # Si habia algo, lo vacia

# Corre el ejecutable
echo -e "\n>>>>>>>>>> Corriendo GDB"
gdb -d "$SOURCE_DIR" --args "$TP2" "$FILTRO" -i "$IMPL" -o "$OUTPUT_DIR" "$IMG" 100 # FIXME corregi el param este que va para Manchas nomas
