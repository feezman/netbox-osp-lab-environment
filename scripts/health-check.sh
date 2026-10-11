#!/usr/bin/env bash

set -u

SERVICES=(
  nginx
  netbox
  netbox-rq
  postgresql
  redis-server
)

echo "=================================="
echo " NetBox-OSP Lab Health Check"
echo "=================================="
echo "Date: $(date)"
echo

PASS=0
FAIL=0

for service in "${SERVICES[@]}"; do
  status=$(systemctl is-active "$service" 2>/dev/null || true)

  if [[ "$status" == "active" ]]; then
    printf "[PASS] %-15s %s\n" "$service" "$status"
    ((PASS+=1))
  else
    printf "[FAIL] %-15s %s\n" "$service" "${status:-unknown}"
    ((FAIL+=1))
  fi
done

echo
echo "----------------------------------"
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "----------------------------------"

if (( FAIL > 0 )); then
  exit 1
fi

exit 0