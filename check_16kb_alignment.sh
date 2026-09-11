#!/bin/bash

# check_16kb_alignment.sh
AAB_FILE="$1"
TEMP_DIR=$(mktemp -d)

READELF="/Users/supercoolcoder/Library/Android/sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-readelf"

if [[ ! -f "$AAB_FILE" ]]; then
    echo "Usage: $0 <path_to_aab_or_apk>"
    exit 1
fi

echo "Unzipping $AAB_FILE to $TEMP_DIR..."
unzip -q "$AAB_FILE" -d "$TEMP_DIR"

echo "Checking .so files for 16KB alignment..."
find "$TEMP_DIR" -name "*.so" -type f | while read so_file; do
    # Get the LOAD segments and extract the alignment
    ALIGNMENTS=$("$READELF" -lW "$so_file" | grep ' LOAD ' | awk '{print $NF}')
    
    IS_BAD=0
    for align in $ALIGNMENTS; do
        # convert hex to decimal
        align_dec=$(printf "%d\n" "$align")
        if [ "$align_dec" -lt 16384 ]; then
            IS_BAD=1
        fi
    done
    
    if [ "$IS_BAD" -eq 1 ]; then
        echo "❌ FAILED: $so_file (Alignments: $(echo $ALIGNMENTS | tr '\n' ' '))"
    else
        echo "✅ OK: $so_file"
    fi
done

rm -rf "$TEMP_DIR"
