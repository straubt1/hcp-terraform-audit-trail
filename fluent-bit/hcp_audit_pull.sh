#!/bin/bash
set -e

# Define the timestamp file path
TIMESTAMP_FILE="/tmp/hcpt-audit-since.txt"
CURRENT_TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%S.000Z')

# Get timestamp from file, if empty or non existent, will be empty string
SINCE=$(cat "$TIMESTAMP_FILE" 2>/dev/null || echo "")
# Check if SINCE is a valid timestamp (ISO 8601 format)
if [[ -z "$SINCE" ]] || ! date -j -f "%Y-%m-%dT%H:%M:%S" "${SINCE%.*}" >/dev/null 2>&1; then
    # Invalid or empty timestamp, set to 1 hour ago
    SINCE=$(date -u -v-1H '+%Y-%m-%dT%H:%M:%S.000Z')
fi

# Check if SINCE is more than 1 hour old
ONE_HOUR_AGO=$(date -u -v-1H '+%Y-%m-%dT%H:%M:%S.000Z')
if [[ "$SINCE" < "$ONE_HOUR_AGO" ]]; then
  # SINCE is more than 1 hour old, set to 1 hour ago
  SINCE="$ONE_HOUR_AGO"
fi

# Fetch logs from audit-trails endpoint
curl -s \
  -H "Authorization: Bearer ${HCPT_API_TOKEN}" \
  "https://app.terraform.io/api/v2/organization/audit-trail?since=${SINCE}" \
  | jq -c '.data[]'

# Write current timestamp minus 10 seconds to file for next run (prevents gaps)
NEXT_SINCE=$(date -u -v-10S '+%Y-%m-%dT%H:%M:%S.000Z')
echo ${NEXT_SINCE} > "$TIMESTAMP_FILE"

# echo "SINCE:             $SINCE"
# echo "CURRENT_TIMESTAMP: $CURRENT_TIMESTAMP"
