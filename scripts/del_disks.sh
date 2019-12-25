#!/usr/bin/env bash

CMD=$(gcloud compute disks list | grep gke-demo-space | awk '{print "gcloud compute disks delete "$1" --zone "$2" --quiet"}')
echo $CMD
