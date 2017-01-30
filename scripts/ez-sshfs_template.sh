#!/bin/bash
sudo sshfs -o allow_other,default_permissions target_user@target_host:target_dir self_dir
