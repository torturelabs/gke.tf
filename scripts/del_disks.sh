#!/usr/bin/env bash

DISKS=$(gcloud compute disks list | grep gke-demo-space)
if [ -z "$DISKS" ]; then
  echo "Nothing to delete"
  exit 0
fi

echo "Make sure that all included disks need to delete:"
echo "$DISKS" | awk '{print $1}'
read -p "Do you wish to proceed? (y/n) " yn

case $yn in
  [Yy]* )
    echo "Deleting..."
    CMD=$(echo "$DISKS" | \
      awk '{print "gcloud compute disks delete "$1" --zone "$2" --quiet && "}')
    CMD="$CMD echo Completed"
    #echo $CMD
    eval $CMD
    ;;
  *) echo "Do nothing..."
esac
