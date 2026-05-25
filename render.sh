#!/usr/bin/env bash
jq -r '
.data[]
|
"──────────────────────────────────",
"\(.person_name_div)",
"\(.nid // "N/A")",
"",
(.verdicts[] |
  "  • \(.label)",
  "    \(.judgement_date) → \(.due_date) | \(.duration_in_words)",
  ""
),
""
' data.json
