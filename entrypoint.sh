#!/bin/bash
#echo 999999 | sudo tee -a /proc/sys/fs/inotify/max_user_watches
#echo 999999 | sudo tee -a /proc/sys/fs/inotify/max_queued_events
#echo 999999 | sudo tee -a /proc/sys/fs/inotify/max_user_instances
#watchman shutdown-server
#sudo sysctl -p
echo fs.inotify.max_user_instances=999999 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
echo fs.inotify.max_user_watches=999999 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
echo fs.inotify.max_queued_events=999999 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
/bin/bash
