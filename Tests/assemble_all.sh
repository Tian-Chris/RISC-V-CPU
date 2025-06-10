#!/bin/bash

# Set gettext lib path to fix runtime linking issue
export DYLD_LIBRARY_PATH="/usr/local/opt/gettext/lib:$DYLD_LIBRARY_PATH"

mkdir -p hex_files

for asmfile in *.s; do
  base="${asmfile%.s}"
  echo "Processing $asmfile..."

  # Assemble
  riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o "$base.o" "$asmfile"
  if [ $? -ne 0 ]; then
    echo "Assembly failed for $asmfile"
    continue
  fi

  # Convert to binary
  riscv64-unknown-elf-objcopy -O binary "$base.o" "hex_files/$base.bin"

  # Convert binary to hex
  hexdump -v -e '1/4 "%08x\n"' "hex_files/$base.bin" > "hex_files/$base.hex"

  # Cleanup object and binary files
  rm "$base.o" "hex_files/$base.bin"

  echo "Done: hex_files/$base.hex"
done

echo "All done!"
