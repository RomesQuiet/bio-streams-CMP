#!/bin/bash
# Records the demo videos (22 Nov 2026; the team's task list, sheet 2) with Godot's Movie Maker.
#
#   tools/record_demo.sh [en|pt] [scenario ...]
#
# With no scenario it records all of them. For each scenario it runs the game with a real window
# (Movie Maker cannot record headless), the user argument --demo=<scenario>
# (scripts/autoload/demo_player.gd plays by itself and quits at the end), writes
# captures/<lang>/<scenario>.avi, converts it to captures/<lang>/<scenario>.mp4 (H.264 and AAC
# audio; the game has no music yet, so the sound track is silent) and deletes the AVI. Screenshots
# go to captures/<lang>/shots/.
#
# The player's own saves and settings are never touched: while it records, an override.cfg in
# the project folder makes Godot use another user folder ("My Healthy Avatar demo"), emptied
# first, and the override is removed at the end, also when the script is stopped.
set -u
cd "$(dirname "$0")/.."
PROJECT="$(pwd)"
GODOT="${GODOT:-/Applications/Godot 2.app/Contents/MacOS/Godot}"
LANG_ID="${1:-en}"
shift || true
SCENARIOS=("$@")
if [ ${#SCENARIOS[@]} -eq 0 ]; then
	SCENARIOS=(menu screens cardio squats push_ups sit_ups meal football video_game sleep health)
fi
OUT="$PROJECT/captures/$LANG_ID"
SHOTS="$OUT/shots"
DEMO_USER_DIR="My Healthy Avatar demo"
USER_DATA="$HOME/Library/Application Support/$DEMO_USER_DIR"
LOG="$OUT/record.log"

if [ ! -x "$GODOT" ]; then
	echo "Godot not found at $GODOT (set GODOT=/path/to/Godot)"; exit 1
fi
if ! command -v ffmpeg >/dev/null; then
	echo "ffmpeg not found: install it with 'brew install ffmpeg'"; exit 1
fi
mkdir -p "$SHOTS"
touch "$PROJECT/captures/.gdignore"
if [ -e "$PROJECT/override.cfg" ]; then
	echo "override.cfg already exists in the project: remove it first"; exit 1
fi
cleanup() { rm -f "$PROJECT/override.cfg"; }
trap cleanup EXIT INT TERM
cat > "$PROJECT/override.cfg" <<EOF
[application]
config/use_custom_user_dir=true
config/custom_user_dir_name="$DEMO_USER_DIR"
EOF

: > "$LOG"
failed=()
for scenario in "${SCENARIOS[@]}"; do
	echo "== $scenario ($LANG_ID)" | tee -a "$LOG"
	rm -rf "$USER_DATA"
	avi="$OUT/$scenario.avi"
	rm -f "$avi"
	"$GODOT" --path "$PROJECT" --resolution 720x1280 --fixed-fps 60 --disable-vsync \
		--write-movie "$avi" -- "--demo=$scenario" "--lang=$LANG_ID" "--shots=$SHOTS" >> "$LOG" 2>&1
	code=$?
	if [ ! -s "$avi" ]; then
		echo "   no video written (Godot exit code $code)" | tee -a "$LOG"
		failed+=("$scenario")
		continue
	fi
	ffmpeg -y -loglevel error -i "$avi" -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p \
		-c:a aac -b:a 128k -movflags +faststart "$OUT/$scenario.mp4" >> "$LOG" 2>&1
	if [ $? -eq 0 ] && [ -s "$OUT/$scenario.mp4" ]; then
		rm -f "$avi"
		length=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT/$scenario.mp4")
		echo "   $OUT/$scenario.mp4 (${length%.*} s, exit code $code)" | tee -a "$LOG"
	else
		echo "   ffmpeg could not convert $avi (kept)" | tee -a "$LOG"
		failed+=("$scenario")
	fi
	[ "$code" -ne 0 ] && failed+=("$scenario (exit $code)")
done
rm -rf "$USER_DATA"
echo "Problems reported by the demo:" ; grep "DEMO ERROR" "$LOG" || echo "   none"
if [ ${#failed[@]} -gt 0 ]; then
	echo "Failed: ${failed[*]}"; exit 1
fi
echo "Done: $OUT"
