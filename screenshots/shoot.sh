#!/usr/bin/env bash
# Take a themed screenshot of a tint demo in a real kitty window.
#
#   screenshots/shoot.sh screenshots/demo-usage.sh screenshots/usage.png
#
# Requires a running Hyprland session with kitty and grim. The window is opened
# on an empty workspace (so no other window overlaps it), with the author's
# kitty palette and font (Iosevka + the neg palette), opaque, cursor hidden.
# The shot is cropped to the window, clipped above the bottom bar (pleamar is a
# layer surface, not an exclusive zone, so it paints over the window), trimmed
# to its content and put on a uniform 1400 px canvas for the README.
#
# The window is deliberately not floated or resized: dispatches act on the
# active window, and doing that while the demo draws produced shots with the
# window below bleeding through. The demo script ends on its own after a few
# seconds, so the window closes cleanly instead of being killed while the
# compositor is still mapping it (that crashed Hyprland 0.57.2 once).
set -euo pipefail

demo=$(realpath "${1:?usage: shoot.sh DEMO OUT.png}")
out=${2:?usage: shoot.sh DEMO OUT.png}
# Workspace to shoot on; must not hold anything else.
shot_workspace=${SHOT_WORKSPACE:-9}

# The caller may be an old process holding a stale signature (the compositor
# restarts), so resolve the live instance explicitly.
export HYPRLAND_INSTANCE_SIGNATURE=$(
  basename "$(ls -td /run/user/"$(id -u)"/hypr/*/ 2>/dev/null | head -1)"
)

# Wait for a previous shot window to close before opening the next one.
for _ in $(seq 150); do
  hyprctl clients -j | jq -e '.[] | select(.class == "tint-shot")' >/dev/null || break
  sleep 0.1
done

prev_workspace=$(hyprctl activeworkspace -j | jq -r '.name // .id')

restore() {
  local pid
  pid=$(hyprctl clients -j 2>/dev/null | jq -r '.[] | select(.class == "tint-shot") | .pid' | head -1)
  [ -n "$pid" ] && kill "$pid" 2>/dev/null || true
  hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = \"$prev_workspace\" }))" >/dev/null 2>&1 || true
  rm -f "$kitty_conf"
}

kitty_conf=$(mktemp --suffix=.conf)
cat >"$kitty_conf" <<EOF
include $HOME/.config/kitty/font.conf
include $HOME/.config/kitty/theme.conf
include $HOME/.config/kitty/mouse.conf
include $HOME/.config/kitty/key.conf
include $HOME/.config/kitty/tab.conf
font_size 13
cursor #000000
cursor_text_color #000000
background_opacity 1.0
cursor_trail 0
tab_bar_min_tabs 99
window_padding_width 6
EOF
trap restore EXIT

# An empty workspace keeps the shot window on top: the tiled layout would
# otherwise leave it under whatever floats over it.
hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = \"$shot_workspace\" }))" >/dev/null
sleep 1.5

monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
scale=$(hyprctl monitors -j | jq -r --arg name "$monitor" '.[] | select(.name == $name) | .scale')

hyprctl eval "hl.dispatch(hl.dsp.exec_cmd('kitty --config $kitty_conf --class tint-shot --title tint bash $demo'))" >/dev/null

for _ in $(seq 100); do
  if hyprctl clients -j | jq -e '.[] | select(.class == "tint-shot" and .mapped)' >/dev/null; then
    break
  fi
  sleep 0.1
done
sleep 3

read -r wx wy ww wh <<<"$(hyprctl clients -j | jq -r '
  .[] | select(.class == "tint-shot") |
  "\(.at[0]) \(.at[1]) \(.size[0]) \(.size[1])"' | head -1)"

# The bar is a layer surface painted over the tiled area; clip the crop at its
# top so a workspace capsule does not leak into the shot.
bar_top=$(hyprctl layers -j | jq -r '
  [to_entries[].value.levels | to_entries[].value[] | select(.w > 1 and .h > 1) | .y] | min // 0')
crop_h=$wh
if [ "$bar_top" -gt "$wy" ] 2>/dev/null && [ "$bar_top" -lt $((wy + wh)) ]; then
  crop_h=$((bar_top - wy))
fi

full=$(mktemp --suffix=.png)
shot=$(mktemp --suffix=.png)
done_marker=$(mktemp --suffix=.done)
rm -f "$done_marker"
hyprctl eval "hl.dispatch(hl.dsp.exec_cmd('grim -o $monitor $full && : > $done_marker'))" >/dev/null
for _ in $(seq 50); do
  [ -e "$done_marker" ] && break
  sleep 0.1
done
rm -f "$done_marker"

crop=$(
  awk -v s="$scale" -v w="$ww" -v h="$crop_h" -v x="$wx" -v y="$wy" \
    'BEGIN { printf "%dx%d+%d+%d", int(w * s), int(h * s), int(x * s), int(y * s) }'
)
magick "$full" -crop "$crop" +repage -trim +repage \
  -bordercolor '#000000' -border 24 "$shot"
magick "$shot" -resize '1400x>' "$shot"
shot_height=$(magick identify -format '%h' "$shot")
magick "$shot" -background '#000000' -gravity west -extent "1400x$shot_height" "$out"
rm -f "$full" "$shot"

echo "wrote $out"
