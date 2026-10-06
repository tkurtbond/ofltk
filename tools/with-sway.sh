#!/bin/sh
# Runs a command on a headless sway, a Wayland compositor with no screen,
# so its windows never appear on the desktop, and exits with its status.
#
#   tools/with-sway.sh make test
#
# sway starts the command itself (exec in its config), so the command gets
# sway's own WAYLAND_DISPLAY and SWAYSOCK, and then tells sway to exit.
# DISPLAY is unset, so FLTK can't fall back to X11. The command runs in
# this directory, and its output goes to this script's.
set -u
[ $# -gt 0 ] || { echo "usage: $0 command [args...]" >&2; exit 2; }
command -v sway >/dev/null || { echo "$0: sway isn't installed" >&2; exit 2; }

dir=$(mktemp -d) || exit 2
trap 'rm -rf "$dir"' EXIT
cwd=$(pwd)

# The command, its arguments quoted for sh.
cmd=""
for a in "$@"; do
  cmd="$cmd '$(printf '%s' "$a" | sed "s/'/'\\\\''/g")'"
done

cat > "$dir/run" <<EOF
#!/bin/sh
cd '$cwd' || exit 2
unset DISPLAY
$cmd > '$dir/out' 2>&1 < /dev/null
echo \$? > '$dir/status'
swaymsg exit > /dev/null
EOF
chmod +x "$dir/run"

cat > "$dir/config" <<EOF
output HEADLESS-1 resolution 1280x800
exec $dir/run
EOF

touch "$dir/out"
env -u DISPLAY -u WAYLAND_DISPLAY -u SWAYSOCK \
  WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 \
  sway -c "$dir/config" > "$dir/sway.log" 2>&1 &
swaypid=$!
# The command's output as it runs; tail reads to the end once sway exits.
tail -n +1 -f --pid=$swaypid "$dir/out"
wait $swaypid
swaystatus=$?

if [ ! -s "$dir/status" ]; then
  echo "$0: sway exited ($swaystatus) before the command finished; its log:" >&2
  cat "$dir/sway.log" >&2
  exit 2
fi
exit "$(cat "$dir/status")"
