#!/usr/bin/env bash
# ssh_failed_logins.sh
# Scans an auth log for failed SSH logins and flags suspicious IPs.
# Usage: ./ssh_failed_logins.sh [log_file] [threshold]

LOG_FILE="${1:-/var/log/auth.log}"
THRESHOLD="${2:-5}"

if [[ ! -r "$LOG_FILE" ]]; then
  echo "Can't read $LOG_FILE. Try running with sudo."
  exit 1
fi

FAILED=$(grep "Failed password" "$LOG_FILE")

if [[ -z "$FAILED" ]]; then
  echo "No failed SSH logins found in $LOG_FILE."
  exit 0
fi

echo "=== SSH Failed Login Report ==="
echo "Log file: $LOG_FILE"
echo "Total failed attempts: $(echo "$FAILED" | wc -l)"
echo

echo "--- Top 10 source IPs ---"
echo "$FAILED" | grep -oE 'from [0-9.]+' | awk '{print $2}' \
  | sort | uniq -c | sort -rn | head -10
echo

echo "--- Top 10 usernames tried ---"
echo "$FAILED" | sed -E 's/.*Failed password for (invalid user )?([^ ]+) from.*/\2/' \
  | sort | uniq -c | sort -rn | head -10
echo

echo "--- IPs at or above $THRESHOLD attempts (suspicious) ---"
echo "$FAILED" | grep -oE 'from [0-9.]+' | awk '{print $2}' \
  | sort | uniq -c | awk -v t="$THRESHOLD" '$1 >= t {print "WARNING: " $2 " (" $1 " attempts)"}'
