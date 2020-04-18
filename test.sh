#!/usr/bin/env bash

#./workspace-rsync.sh -f "helloworld.conf"
#
./workspace-rsync.sh --ssh kevin@192.168.0.1 --ssh-key $HOME/.ssh/id_rsa --local $(pwd) --remote /mnt/myProject --diff_time 3

