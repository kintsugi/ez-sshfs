#!/bin/bash
[ -z "$self_host" ] && echo "Need to set self_host with accessible IP of current machine" && exit 1;

ez_sshfs_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
script_dir=$ez_sshfs_dir/scripts/
data_dir=$ez_sshfs_dir/data/

name=$1
remote_flag=false;

remote_script_file=$script_dir/sshfs_"$name"_remote.sh
host_script_file=$script_dir/sshfs_"$name".sh
data_file=$data_dir/data_$name

if [ ! -f  $remote_script_file ] || [ ! -f  $host_script_file ] || [ ! -f  $data_file ]; then
  echo "ez-sshfs not initalized for this target!" && exit 1;
fi

# read values from data file
source $data_file

while getopts "r" opt; do
  case $opt in
    r)
      remote_flag=$OPTARG
      ;;
  esac
done

#if $stop ; then
  #sudo umount -f self_dir 
  #if $remote_flag ; then
    #ssh $target_user@$target_host 'sudo umount -f $target_dir'
  #fi
  #exit 1;
#fi

if ! $remote_flag ; then
  $host_script_file
else
  ssh $target_user@$target_host '~/.sshfs_$name.sh'
fi
