#!/usr/bin/env bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WORK_DIR=$(pwd)

mkdir -p $HOME/.ws-rsync/

function usage
{
    echo "basically, workspace-rsync will create .config_<name-of-workspace-dir> in your $HOME when you run the utility with out any confile\\
          then the tool will check whether or not the configure in $HOME then it will auto apply the configure"

    echo "usage: workspace-rsync -w your_dir_path -d diff_time : for monitoring your directory and re-update local hugo web"
    echo "usage: hugo_ascii_cmder -r 'hugo command here' : for monitoring your directory and re-update local hugo web"

    echo "usage: workspace-rsync -f $(pwd)/.myconfig_for_the_workspace"
    echo "usage: workspace-rsync --ssh keivn@my-sample-server --ssh-key $HOME/.ssh/sample_key --local $(pwd) --remote /mnt/my-project/"

    echo "   ";
    echo "  -f | --config_file      ; your configure file";
    echo "  --ssh                   : Your ssh account kevin@kencancode ";
    echo "  --ssh-key               : your ssh private key absolute path <~/home/kevin/.ssh/id_rsa>";
    echo "  --local                 : local work space dir ~/Project/KEVIN/TestABC ";
    echo "  --remote                : remote work space dir /mnt/KEVIN/TestABC";
    echo "  --diff_time         : diff_time to check changed on local side";
    echo "  -h | --help             : Help";
}


function parse_args
{
  # positional args
  args=()

  # named args
  while [[ "$1" != "" ]]; do
      case "$1" in
          -f | --config_file )                  cfg_file="$2";  shift;;
          --ssh )                               ssh_acc="$2";   shift;;
          --ssh-key )                           ssh_key="$2";   shift;;
          --local )                          local_dir="$2";   shift;;
          --remote )                         remote_dir="$2";   shift;;
          --diff_time )                      diff_time="$2"; shift;;
          -h | --help )                         usage;          exit;; # quit and show usage
          * )                           args+=("$1")             # if no match, add it to the positional args
      esac
      shift # move to next kv pair
  done
  # restore positional args
  set -- "${args[@]}"
}

watch_dir() {
    echo watching folder $1/ every $2 secs.
    while [[ true ]]
    do
        files=`find $1 -type f -newermt "$2 seconds ago"`
        if [[ ${files} != "" ]] ; then
            docker stop hugo-ascii-runner
            sleep 1
            hugo_ascii_docker_run -D
            sleep 1
            cp -rf ${ROOT_DIR}/assets ${ROOT_DIR}/static/
            sleep 1
            hugo_ascii_docker_run "server -D"
        fi
        sleep 3
    done
}

function get_ws_config(){
    return
}

function write_ws_config(){
    ws_cfg_file=$HOME/.ws-rsync/.config_"${PWD##*/}"
    echo "ws configure file: $ws_cfg_file"
    echo "clean up the workspace configure file"
    echo  > ${ws_cfg_file}

    if [[ ! -z ${cfg_file} ]]; then
        echo "(${!cfg_file@})=$cfg_file" >> ${ws_cfg_file}
    fi

    if [[ ! -z ${ssh_acc} ]]; then
        echo "${!ssh_acc@}=$ssh_acc" >> ${ws_cfg_file}
    fi

    if [[ ! -z ${ssh_key} ]]; then
        echo "${!ssh_key@}=$ssh_key" >> ${ws_cfg_file}
    fi

    if [[ ! -z ${local_dir} ]]; then
        echo "${!local_dir@}=$local_dir" >> ${ws_cfg_file}
    fi

    if [[ ! -z ${local_dir} ]]; then
        echo "${!local_dir@}=$local_dir" >> ${ws_cfg_file}
    fi

    if [[ ! -z ${remote_dir} ]]; then
        echo "${!remote_dir@}=$remote_dir" >> ${ws_cfg_file}
    fi

    if [[ ! -z ${diff_time} ]]; then
        echo "${!diff_time@}=$diff_time" >> ${ws_cfg_file}
    fi

    return;
}

function validate_ws_config(){
    return
}

function run_configue{
    return;
}

function run_action_remote_local_sync{
    return
}

function run_action_local_remote_sync{
    return;
}

function run_action{
    return
}

# ws-rsync.sh init : you will run the initial steps for the current workspace dir"
# run the command bellow to update your configure which already done in initial step
# ws-rsync.sh config --ssh kevin@exampleserver --ssh-key $HOME/.ssh/examplekey ...
# After inital/configue then can use the script to run some action
# by default, the script will run the default action monitoring and sync the workspace
# with daemon options, then script will run in background for example
# ws-rsync.sh run --daemon  : workspace-rsync will monitor your configured workspace
# when we think that remote side is latest version, then we need to sync up with remote site. In this case, that we will
# download the newer files from remote workspace
# ws-rsync.sh run remote-local-sync : run a sync up from local to remote: rsync download newer from remote to local/ scp download-replace everything from remote to local
# when we think that local side is latest version, then we need to update the newer files to remote workspace
# ws-rsync.sh run local-remote-sync : run a sync up from local to remote: rync  upload the newer from local to remote....
function run
{
  parse_args "$@"
  #  TODO need to check current dir is already have configure or not.
  echo "named arg: config_file: $cfg_file"
  echo "named arg: ssh : $ssh_acc"
  echo "named arg: ssh-key: $ssh_key"
  echo "named arg: local: $local_dir"
  echo "named arg: remote: $remote_dir"
  echo "named arg: diff_time: $diff_time"
  write_ws_config
}

run "$@";