#! /usr/bin/env bash

# vamos a usar esta imagen para correr el debugger.
IMG="data/imagenes_a_testear/NoCountryForOldMen.32x18.bmp"

# Ejecutable
TP2="../build/tp2"

# FIXME hacelo parametro
FILTRO="Manchas"

# FIXME hacelo parametro
IMPL="asm"

OUTPUT_DIR="data/resultados_debugging"

# ----------------------------------------------------------------------------

# Corre make
echo -e "\n>>>>>>>>>> Corriendo Make"
cd .. && make && cd tests

# Se asegura que la imagen exista
if [[ ! -f "$IMG" ]]; then
    echo -e "\n>>>>>>>>>> Generando Imagenes"
    ./1_generar_imagenes.py
fi

mkdir -p "$OUTPUT_DIR" # Hace directorio vacio para tirar la salida
rm -f    "$OUTPUT_DIR/*" # Si habia algo, lo vacia

# Corre el ejecutable
echo -e "\n>>>>>>>>>> Corriendo GDB"
gdb --args "$TP2" "$FILTRO" -i "$IMPL" -o "$OUTPUT_DIR" "$IMG" 100 # FIXME corregi el param este que va para Manchas nomas
