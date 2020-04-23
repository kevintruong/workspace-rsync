#!/usr/bin/env bash

./ws-rsync config \
    --ssh-acc vu.truong@kencancode.xyz \
    --ssh-port 16022 \
    --ssh-key $HOME/.ssh/id_rsa \
    --local $(pwd) \
    --remote /tmp/ \
    --diff_time 3

./ws-rsync start
#./ws-rsync.sh run start






