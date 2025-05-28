#!/usr/bin/env bash
#
# This script will modify Amber's FEW to support glycans.
# $AMBERHOME/AmberTools/src/FEW/libs/common_prepare_MD.pm will be modified and
# to run the FEWer scipt mod_leap_glycan.sh.
#
# 2025-05-28    0.1      Andreas    First version
#
if [ -z "$AMBERHOME" ]; then
    echo "AMBERHOME environment variable not set. Quitting..."
    exit 1
fi

f="${AMBERHOME}/AmberTools/src/FEW/libs/common_prepare_MD.pm"
if [ ! -f "$f" ]; then
    echo "File $f not found! Quitting..."
    exit 1
fi

done=$(grep "Modified by FEWer" "$f")
if [ -n "$done" ]; then
    echo "File $f is already modified. Quitting..."
    exit 1
fi

# Make a backup copy
cp "$f" "${f}.bak"
if [ $? -ne 0 ]; then
    echo "Error! Backup copy failed. Do you need to be a superuser?"
    exit 1
fi

echo "Modifing $f to support glycans..."

sed -i '/my $f_leap_log = $cryst_dir."\/leap_1.log";/i \
                # Modified by FEWer to support glycans\
                print `..\/..\/FEWer\/mod_leap_glycan.sh 1`;\
' "$f"

sed -i '/# Second Leap call/i \
                # Modified by FEWer to support glycans\
                print `..\/..\/FEWer\/mod_leap_glycan.sh 2`;\
' "$f"
