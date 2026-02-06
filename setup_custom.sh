#!/bin/bash
# ==============================================================================
# Setup script to switch between ADI original and custom data capture
# ==============================================================================

PROJ_DIR="$(cd "$(dirname "$0")" && pwd)"
COMMON_DIR="$PROJ_DIR/../common"

backup_original() {
    echo "Backing up original files..."
    if [ ! -f "$PROJ_DIR/system_bd_original.tcl" ]; then
        cp "$PROJ_DIR/system_bd.tcl" "$PROJ_DIR/system_bd_original.tcl"
    fi
    if [ ! -f "$PROJ_DIR/system_top_original.v" ]; then
        cp "$PROJ_DIR/system_top.v" "$PROJ_DIR/system_top_original.v"
    fi
    if [ ! -f "$COMMON_DIR/ad4134_bd_original.tcl" ]; then
        cp "$COMMON_DIR/ad4134_bd.tcl" "$COMMON_DIR/ad4134_bd_original.tcl"
    fi
}

use_custom() {
    echo "Switching to CUSTOM data capture design..."
    backup_original

    # Replace system_bd.tcl to source custom ad4134_bd
    cp "$PROJ_DIR/system_bd_custom.tcl" "$PROJ_DIR/system_bd.tcl"

    # Replace system_top.v with custom version
    cp "$PROJ_DIR/system_top_custom.v" "$PROJ_DIR/system_top.v"

    # Replace ad4134_bd.tcl with custom version
    cp "$COMMON_DIR/ad4134_bd_custom.tcl" "$COMMON_DIR/ad4134_bd.tcl"

    echo "Done! Custom design is now active."
    echo "Build with: make"
}

use_original() {
    echo "Switching to ORIGINAL ADI SPI Engine design..."

    if [ -f "$PROJ_DIR/system_bd_original.tcl" ]; then
        cp "$PROJ_DIR/system_bd_original.tcl" "$PROJ_DIR/system_bd.tcl"
    else
        echo "ERROR: Original system_bd.tcl backup not found"
        exit 1
    fi

    if [ -f "$PROJ_DIR/system_top_original.v" ]; then
        cp "$PROJ_DIR/system_top_original.v" "$PROJ_DIR/system_top.v"
    else
        echo "ERROR: Original system_top.v backup not found"
        exit 1
    fi

    if [ -f "$COMMON_DIR/ad4134_bd_original.tcl" ]; then
        cp "$COMMON_DIR/ad4134_bd_original.tcl" "$COMMON_DIR/ad4134_bd.tcl"
    else
        echo "ERROR: Original ad4134_bd.tcl backup not found"
        exit 1
    fi

    echo "Done! Original ADI design is now active."
    echo "Build with: make"
}

case "$1" in
    custom)
        use_custom
        ;;
    original)
        use_original
        ;;
    *)
        echo "Usage: $0 {custom|original}"
        echo ""
        echo "  custom   - Use custom VHDL data capture (ad4134_data )"
        echo "  original - Use original ADI SPI Engine data capture"
        exit 1
        ;;
esac

