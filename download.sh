#!/usr/bin/env bash
set -euo pipefail

OUTDIR="./images"
mkdir -p "$OUTDIR"

content_type_to_ext() {
  local ct="${1%;*}"
  case "$ct" in
    image/jpeg|image/jpg) echo ".jpg" ;;
    image/png)            echo ".png" ;;
    image/webp)           echo ".webp" ;;
    image/gif)            echo ".gif" ;;
    image/bmp)            echo ".bmp" ;;
    *)                    echo ".jpg" ;;
  esac
}

total=0
downloaded=0
skipped=0
failed=0

SENTINEL="__NULL__"

while IFS=$'\t' read -r nid passport file_url judgement_date desc_b64; do
  total=$((total + 1))

  [[ "$nid" == "$SENTINEL" ]] && nid=""
  [[ "$passport" == "$SENTINEL" ]] && passport=""
  [[ "$file_url" == "$SENTINEL" ]] && file_url=""
  [[ "$judgement_date" == "$SENTINEL" ]] && judgement_date=""

  if [[ -z "$nid" && -z "$passport" ]]; then
    echo "WARN: entry #$total — no NID or passport, skipping" >&2
    skipped=$((skipped + 1))
    continue
  fi

  if [[ -z "$file_url" ]]; then
    echo "WARN: entry #$total — no file_url, skipping" >&2
    skipped=$((skipped + 1))
    continue
  fi

  id="${nid:-$passport}"

  content_type=$(curl -sIL -o /dev/null -w '%{content_type}' "$file_url" 2>/dev/null || true)
  ext=$(content_type_to_ext "$content_type")
  output="$OUTDIR/${id}${ext}"

  if [[ -f "$output" ]]; then
    echo "[#$total] SKIP: $output already exists" >&2
    skipped=$((skipped + 1))
    continue
  fi

  echo "[#$total] DOWNLOAD: $id → $output" >&2

  if ! curl -fSLs -o "$output" "$file_url"; then
    echo "[#$total] ERROR: download failed for $id ($file_url)" >&2
    rm -f "$output"
    failed=$((failed + 1))
    continue
  fi

  desc=$(echo "$desc_b64" | base64 -d)

  exif_args=(-overwrite_original -ImageDescription="$desc")
  if [[ -n "$judgement_date" ]]; then
    datetime_orig="${judgement_date//-/":"} 00:00:00"
    exif_args+=(-DateTimeOriginal="$datetime_orig")
  fi

  if exiftool "${exif_args[@]}" "$output" >/dev/null 2>&1; then
    downloaded=$((downloaded + 1))
    echo "[#$total] DONE: $id" >&2
  else
    echo "[#$total] WARN: metadata write failed for $id (image saved)" >&2
    downloaded=$((downloaded + 1))
  fi
done < <(jq -r '
.data[]
| [
    (.nid // "__NULL__"),
    (.passport // "__NULL__"),
    (.file_url // "__NULL__"),
    ([.verdicts[].judgement_date] | min // "__NULL__"),
    (
      "──────────────────────────────────\n" +
      "\(.person_name_div)\n" +
      "\(.nid // "N/A")\n" +
      "\n" +
      (.verdicts | map("  • \(.label)\n    \(.judgement_date) → \(.due_date) | \(.duration_in_words)\n") | join("\n"))
      + "\n"
      | @base64
    )
]
| @tsv
' data.json)

echo
echo "Done. $total entries: $downloaded downloaded, $skipped skipped, $failed failed." >&2
