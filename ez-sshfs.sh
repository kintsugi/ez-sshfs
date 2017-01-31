#!/bin/bash
bin_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

[ -z "$self_host" ] && echo "Need to set self_host with accessible IP of current machine" && exit 1;
[ ! -z "$ez_sshfs_dir" ] && ez_sshfs_dir=~/.ez-sshfs

if [ ! -d $ez_sshfs_dir ]; then
  mkdir -p $ez_sshfs_dir 
  mkdir $ez_sshfs_dir/scripts
  mkdir $ez_sshfs_dir/data
  cp $bin_dir/scripts/ez-sshfs_template.sh $ez_sshfs_dir/scripts/ez-sshfs_template.sh
  cp $bin_dir/data/template $ez_sshfs_dir/data/template
fi

script_dir=$ez_sshfs_dir/scripts/
data_dir=$ez_sshfs_dir/data/

action=$1
name=$2
target_host=""
self_dir=""
target_dir=""
self_user=$USER
target_user="root"
remote_flag=false

remote_script_file=$script_dir/sshfs_"$name"_remote.sh
host_script_file=$script_dir/sshfs_"$name".sh
data_file=$data_dir/data_$name

OPTIND=3
while getopts ":h:d:t:u:U:n:rx" opt; do
  case $opt in
    h)
      target_host=$OPTARG
      ;;
    d)
      self_dir=$OPTARG
      if [ ! -d $self_dir ]; then
        mkdir -p $self_dir
      fi
      self_dir=`cd "$self_dir"; pwd`

      ;;
    t)
      target_dir=$OPTARG
      ;;
    u)
      self_user=$OPTARG
      ;;
    U)
      target_user=$OPTARG
      ;;
    r)
      remote_flag=true
      ;;
  esac
done


init_ez_sshfs() {

  echo "self: $self_host"
  echo "self dir: $self_dir"
  echo "self user: $self_user"
  echo "target: $target_host"
  echo "target dir: $target_dir"
  echo "target user: $target_user"

  data_file=$data_dir"data_$name"
  cp $data_dir"template" $data_file

  sed -i '.bak' "s#data_target_host#$target_host#g" $data_file
  sed -i '.bak' "s#data_self_dir#$self_dir#g" $data_file
  sed -i '.bak' "s#data_target_dir#$target_dir#g" $data_file
  sed -i '.bak' "s#data_self_user#$self_user#g" $data_file
  sed -i '.bak' "s#data_target_user#$target_user#g" $data_file

  # copy template scripts to be filled out with proper values
  cp $script_dir"ez-sshfs_template.sh" $remote_script_file
  cp $script_dir"ez-sshfs_template.sh" $host_script_file
  chmod +x $remote_script_file
  chmod +x $host_script_file

  # fill out script to sshfs from this machine to the target
  sed -i '.bak' "s#target_user#$target_user#g" $host_script_file
  sed -i '.bak' "s#target_host#$target_host#g" $host_script_file
  sed -i '.bak' "s#target_dir#$target_dir#g" $host_script_file
  sed -i '.bak' "s#self_dir#$self_dir#g" $host_script_file

  # fill out script to sshfs from target to this machine
  sed -i '.bak' "s#target_user#$self_user#g" $remote_script_file
  sed -i '.bak' "s#target_host#$self_host#g" $remote_script_file
  sed -i '.bak' "s#target_dir#$self_dir#g" $remote_script_file
  sed -i '.bak' "s#self_dir#$target_dir#g" $remote_script_file

  echo "ez-sshfs setup complete."
}

start_ez_sshfs() {
  if [ ! -f  $remote_script_file ] || [ ! -f  $host_script_file ] || [ ! -f  $data_file ]; then
    echo "ez-sshfs not initalized for this target!" && exit 1;
  fi

  source $data_file

  if ! $remote_flag ; then
    $host_script_file
  else 
    echo "Not yet supported. Run this command on remote:"
    echo "$(cat $remote_script_file)"
  fi
}

stop_ez_sshfs() {
  if [ ! -f  $remote_script_file ] || [ ! -f  $host_script_file ] || [ ! -f  $data_file ]; then
    echo "ez-sshfs not initalized for this target!" && exit 1;
  fi

  source $data_file

  if ! $remote_flag ; then
    sudo umount -f $self_dir
  else 
    ssh $target_user@$target_host "sudo umount -f $target_dir"
  fi
}

if [ "$action" == "init" ]; then
  init_ez_sshfs
elif [ "$action" == "start" ]; then
  start_ez_sshfs
elif [ "$action" == "stop" ]; then
  stop_ez_sshfs
fi

