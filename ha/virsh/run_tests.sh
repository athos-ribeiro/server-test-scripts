#!/bin/bash

: "${TESTS:=$(echo tests/*_test.sh)}"

# shellcheck disable=SC1091
source /etc/profile.d/libvirt-uri.sh

test_failed=()
for file in $TESTS; do
  if [[ "$file" == "fence_ipmilan_test.sh" ]]; then
    continue
  fi

  AGENT=$(echo "$file" | grep -oP '(?<=/).+(?=\_)' | tr _ -)
  export AGENT=$AGENT

  # Cleanup stale VMs
  ./delete-cluster.sh || exit 1

  if [[ "$AGENT" == "fence-scsi" ]]  || \
     [[ "$AGENT" == "fence-mpath" ]] || \
     [[ "$AGENT" == "fence-sbd" ]]   || \
     [[ "$AGENT" == "resource-iscsi-target" ]] ; then
    ./setup-cluster.sh --iscsi-shared-device
  elif [[ "$AGENT" == "resource-iscsi-initiator" ]] ; then
    ./setup-cluster.sh --iscsi-target-only
  else
    ./setup-cluster.sh
  fi

  if ! bash "$file"; then
    test_failed+=("$file")
  fi
  ./delete-cluster.sh
done

if [ ${#test_failed[@]} -gt 0 ]; then
  echo -e "\033[0;31mThere are failing tests: [ ${test_failed[@]} ]\033[0m"
  exit 3
fi

echo -e "\033[0;32mAll tests successfully passed!\033[0m"
