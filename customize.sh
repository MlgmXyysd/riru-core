SKIPUNZIP=1
RIRU_PATH="/data/misc/riru"
RIRU_API=4

# check architecture
if [[ "$ARCH" != "arm" && "$ARCH" != "arm64" && "$ARCH" != "x86" && "$ARCH" != "x64" ]]; then
  abort "! Unsupported platform: $ARCH"
else
  ui_print "- Device platform: $ARCH"
fi

unzip -o "$ZIPFILE" 'verify.sh' -d "$TMPDIR" >&2
if [[ ! -f "$TMPDIR/verify.sh" ]]; then
  ui_print "*********************************************************"
  ui_print "! Unable to extract verify.sh!"
  ui_print "! This zip may be corrupted, please try downloading again"
  abort    "*********************************************************"
fi
. $TMPDIR/verify.sh

ui_print "- Extracting Magisk files"

extract "$ZIPFILE" 'module.prop' "$MODPATH"
extract "$ZIPFILE" 'post-fs-data.sh' "$MODPATH"
extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"

mkdir -p "$RIRU_PATH/modules"

if [[ "$ARCH" == "x86" || "$ARCH" == "x64" ]]; then
  ui_print "- Extracting x86 libraries"
  extract "$ZIPFILE" 'system_x86/lib/libmemtrack.so' "$MODPATH"
  mv "$MODPATH/system_x86/lib" "$MODPATH/system/lib"

  if [[ "$IS64BIT" == "true" ]]; then
    ui_print "- Extracting x64 libraries"
    extract "$ZIPFILE" 'system_x86/lib64/libmemtrack.so' "$MODPATH"
    mv "$MODPATH/system_x86/lib64" "$MODPATH/system/lib64"
  fi
else
  ui_print "- Extracting arm libraries"
  extract "$ZIPFILE" 'system/lib/libmemtrack.so' "$MODPATH"

  if [[ "$IS64BIT" == "true" ]]; then
    ui_print "- Extracting arm64 libraries"
    extract "$ZIPFILE" 'system/lib64/libmemtrack.so' "$MODPATH"
  fi
fi

ui_print "- Extracting zygote_restart executable"
extract "$ZIPFILE" "zygote_restart/zygote_restart_$ARCH" "$RIRU_PATH/bin" "true"
mv "$RIRU_PATH/bin/zygote_restart_$ARCH" "$RIRU_PATH/bin/zygote_restart"
set_perm "$RIRU_PATH/bin/zygote_restart" 0 0 0700 u:object_r:system_file:s0

ui_print "- Writing api version file"
echo -n "$RIRU_API" > "$RIRU_PATH/api_version"
set_perm "$RIRU_PATH/api_version" 0 0 0600 u:object_r:system_file:s0

ui_print "- Setting permissions"
set_perm_recursive "$MODPATH" 0 0 0755 0644