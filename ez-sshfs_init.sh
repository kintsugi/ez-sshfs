#!/bin/bash
# Given a target host, a target directory on the current machine, and a target directory on the target host, create a script to allow easy bidirectional sshfs 
[ -z "$self_host" ] && echo "Need to set self_host with accessible IP of current machine" && exit 1;

ez_sshfs_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
script_dir=$ez_sshfs_dir/"scripts/"
data_dir=$ez_sshfs_dir/"data/"

target_host=""
self_dir=""
target_dir=""
self_user=$USER
target_user="root"
name=""

while getopts ":h:d:t:u:r:n:" opt; do
  case $opt in
    h)
      target_host=$OPTARG
      ;;
    d)
      self_dir=$OPTARG
      ;;
    t)
      target_dir=$OPTARG
      ;;
    u)
      self_user=$OPTARG
      ;;
    r)
      target_user=$OPTARG
      ;;
    n)
      name=$OPTARG
      ;;
  esac
done

# Check if dir on current machine exists, if not create it
if [ ! -d "$self_dir" ]; then
  mkdir -p $self_dir
fi

self_dir=`cd "$self_dir"; pwd`

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


# target uses this script to mount this machine to theirs
remote_script_file=$script_dir"sshfs_"$name"_remote.sh"
# this machine uses this script to mount the targets machine to this machine
host_script_file=$script_dir"sshfs_"$name".sh"

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

echo "copying script to remote machine..."
scp $remote_script_file $target_user@$target_host:~/sshfs_$name.sh

echo "sshfs setup complete."
echo "ez-sshfs $name to mount the remote to this machine."
echo "ez-sshfs $name -r to mount your machine to the target."
