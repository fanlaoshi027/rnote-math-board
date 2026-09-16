#!/bin/bash
set -euo pipefail

APP_NAME="墨写.app"
APP_DIR="dist/$APP_NAME"
RES="$APP_DIR/Contents/Resources"
SCHEMA_DIR="$RES/glib-2.0/schemas"
mkdir -p "$SCHEMA_DIR"

# Rnote schema
find . -type f -name 'com.github.flxzt.rnote.gschema.xml' -exec cp -f {} "$SCHEMA_DIR/" \;

# Bundle GTK/GLib GSettings schemas from the staged installation when available.
for root in "stage/usr/share" "stage/share" "/opt/homebrew/share" "/usr/local/share"; do
  if [ -d "$root/glib-2.0/schemas" ]; then
    find "$root/glib-2.0/schemas" -maxdepth 1 -type f -name '*.xml' -exec cp -f {} "$SCHEMA_DIR/" \; || true
  fi
done

# Compile the complete schema set. The app must carry its own compiled schemas.
if command -v glib-compile-schemas >/dev/null 2>&1; then
  glib-compile-schemas "$SCHEMA_DIR"
fi

# Ensure GSettings uses the bundled schema directory at runtime.
mkdir -p "$APP_DIR/Contents/MacOS"
cat > "$APP_DIR/Contents/MacOS/launch-mosuan" <<'EOF'
#!/bin/bash
set -e
HERE="$(cd "$(dirname "$0")/.." && pwd)"
export GSETTINGS_SCHEMA_DIR="$HERE/Resources/glib-2.0/schemas"
exec "$HERE/MacOS/rnote" "$@"
EOF
chmod +x "$APP_DIR/Contents/MacOS/launch-mosuan"

# Keep the existing executable/packaging flow if the project provides it.
if [ -x "$APP_DIR/Contents/MacOS/rnote" ]; then
  echo "Bundled GSettings schemas: $(find "$SCHEMA_DIR" -name '*.xml' | wc -l | tr -d ' ') XML files"
fi
