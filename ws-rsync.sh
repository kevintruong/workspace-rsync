#!/usr/bin/env bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CUR_WORK_DIR=$(pwd)
ProgName=$(basename $0)

DEFAULT_DIFF_TIME=3

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
    echo "  --ssh                   : Your ssh account kevin@kencancode ";
    echo "  --ssh-key               : your ssh private key absolute path <~/home/kevin/.ssh/id_rsa>";
    echo "  --local                 : local work space dir ~/Project/KEVIN/TestABC ";
    echo "  --remote                : remote work space dir /mnt/KEVIN/TestABC";
    echo "  --diff_time         : diff_time to check changed on local side";
    echo "  -h | --help             : Help";
}


function parse_conf_args
{
  # positional args
  args=()

  # named args
  while [[ "$1" != "" ]]; do
      case "$1" in
          --ssh )                               ssh_acc="$2";   shift;;
          --ssh-port)                           ssh_port="$2"; shift;;
          --ssh-pass )                          ssh_pass="$2";   shift;;
          --ssh-key )                           ssh_key="$2";   shift;;
          --local )                             local_dir="$2";   shift;;
          --remote )                            remote_dir="$2";   shift;;
          --diff_time )                         diff_time="$2"; shift;;
          -h | --help )                         usage;          exit;; # quit and show usage
          * )                           args+=("$1")             # if no match, add it to the positional args
      esac
      shift # move to next kv pair
  done
  set -- "${args[@]}"
}

watch_dir_inotify(){
    return
}

function rsync_files_to_remote(){
    echo "rsync_files_to_remote"
    changed_file=$1
    local_realpath=$(realpath --relative-to=${local_dir} ${changed_file})
    SSH_OPTS="ssh -T -o Compression=no -x"
    RSYNC_CMD="rsync -aHAXxv --numeric-ids --delete --progress"
    if [[ ! -z ${ssh_port} ]]; then
       SSH_OPTS="$SSH_OPTS -p ${ssh_port}"
    fi
    if [[ -z ${ssh_key} ]];then
        SSHPASS_CMD="sshpass -p$ssh_pass"
        RSYNC_TO_REMOTE_CMD="${SSHPASS_CMD} ${RSYNC_CMD} -e \"$SSH_OPTS\" ${changed_file} ${ssh_acc}:\"$remote_dir/$local_realpath\""
    else
        RSYNC_CMD="rsync -aHAXxv --numeric-ids --delete --progress -e \""
        RSYNC_TO_REMOTE_CMD="${RSYNC_CMD}\"$SSH_OPTS\" ${changed_file} ${ssh_acc}:$remote_dir/$local_realpath"
    fi
    rsync_cmd=$(printf "%q " ${RSYNC_TO_REMOTE_CMD};echo)
    printf "${rsync_cmd}" | bash
    return
}


watch_dir() {
    ws_cfg_file=$(get_ws_config_file)
    . ${ws_cfg_file}

    if [[ -z "${diff_time}" ]];then
        diff_time=3
    fi
    abs_local_dir=$(echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")")
    echo watching folder ${abs_local_dir} every ${diff_time} secs.

    while [[ true ]]
    do
        files=`find ${abs_local_dir} -type f -newermt "$diff_time seconds ago"`
        if [[ ${files} != "" ]] ; then
            echo "${files} changed"
            echo "run update file to remote side"
            rsync_files_to_remote ${files}
        fi
        sleep ${diff_time}
    done
}

function get_ws_config_file() {
    ASB_DIR_PATH=${CUR_WORK_DIR}
    MD5_CUR_DIR=$(echo -n ${ASB_DIR_PATH} | md5sum | awk '{print $1}')
    echo "$HOME/.ws-rsync/.config_${MD5_CUR_DIR}"
}

function get_ws_config(){
    ws_cfg_file=$(get_ws_config_file)
    echo "Configure file is: $ws_cfg_file"
    if [[ ! -f "$ws_cfg_file" ]]; then
        echo 0
    fi
    . "${ws_cfg_file}"
    return 1
}

function write_ws_config(){
    ws_cfg_file=$(get_ws_config_file)
    echo "ws configure file: $ws_cfg_file"
    echo "clean up the workspace configure file"
    echo  > ${ws_cfg_file}

    if [[ ! -z ${ssh_acc} ]]; then
        echo "${!ssh_acc@}=$ssh_acc" >> ${ws_cfg_file}
    fi

    if [[ ! -z ${ssh_key} ]]; then
        echo "${!ssh_key@}=$ssh_key" >> ${ws_cfg_file}
    fi

    if [[ ! -z ${ssh_port} ]]; then
        echo "${!ssh_port@}=$ssh_port" >> ${ws_cfg_file}
    fi

    if [[ ! -z ${ssh_pass} ]]; then
        echo "${!ssh_pass@}=$ssh_pass" >> ${ws_cfg_file}
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

    if [[ -z ${diff_time} ]];then
        diff_time=${DEFAULT_DIFF_TIME}
    fi

    if [[ ! -z ${diff_time} ]]; then
        echo "${!diff_time@}=$diff_time" >> ${ws_cfg_file}
    fi

    # if diff_time is NULL then add default value is 3 secs

    return;
}

function validate_ssh_connection(){
    ws_cfg_file=$(get_ws_config_file)
    if [[ -z "$ws_cfg_file" ]];then
        echo "error on get configure"
        run_init
    fi
    . ${ws_cfg_file}

    if [[ -z ${ssh_key} ]];then
        if [[ ! -z ${ssh_pass} ]];then
            echo "sshpass -p${ssh_pass} ssh -q ${ssh_acc} exit"
            retVal=$(sshpass -p${ssh_pass} ssh -p ${ssh_port} ${ssh_acc} exit);
            if [[ ${retVal} == 255 ]];then
                echo "ssh connection is not active"
                read -r "Press any key to continue or Ctrl-C to exit:"
            fi
        fi
    else
        if [[ ! -z ${ssh_pass} ]];then
            retVal=$(ssh -q -i ${ssh_key} ${ssh_acc} exit);
            if [[ ${retVal} == 255 ]];then
                echo "ssh connection is not active"
                read -r "Press any key to continue or Ctrl-C to exit:"
            fi
        fi
    fi
}

function validate_ws_config(){
    echo "please wait for validate configure"
    echo "validating local dir $local_dir"
    ws_cfg_file=$(get_ws_config_file)
    . ${ws_cfg_file}
    temp=""
    if [[ ! -d ${local_dir} ]]; then
        echo "Warmning look like $local_dir is not existed"
        read -r 'Press any key to continue or Ctrl-C to exit:' temp
        echo "create $local_dir"
        mkdir -p ${local_dir}
    fi
    echo "Validating ssh connection"
    validate_ssh_connection
    return
}

function validate_bool_input(){
    input="${1^^}" # capitalized input
    if [[ "${input}" == "NO" ]];then
        echo 0
    elif [[ "${input}" == "YES" ]];then
        echo 1
    else
        echo -1
    fi
}

function input_ssh_authenticate(){
    read -p 'Using private key to authenticate,default Yes (yes/no)': auth_private_key
    if [[ -z "${auth_private_key}" ]]; then
        auth_private_key="yes"
    fi
    auth_private_key=$(validate_bool_input ${auth_private_key})
    if [[ ${auth_private_key} == -1 ]]; then
        echo "Error on options using private key or not"
        auth_private_key=1
    fi
    if [[ ${auth_private_key} == 1 ]]; then
         read -p 'Enter your ssh private key:' ssh_key
    else
        read -sp 'Enter your ssh password: \n' ssh_pass
    fi
    read -p 'Enter your ssh port (Enter for default: 22) :' ssh_port
    if [[ -z ${ssh_port} || $((ssh_port)) != $ssh_port ]];then
        ssh_port=22
    fi
}

function run_init(){
    echo "run_init"
    local_dir=$(pwd)
    read -p "Enter your ssh account:" ssh_acc
    input_ssh_authenticate
    read -p "Enter your remote workspace:" remote_dir
    write_ws_config
    return
}

function run_configue(){
    ws_cfg_file=$(get_ws_config_file)
    if [[ -f "$ws_cfg_file" ]]; then
        . ${ws_cfg_file}
    fi
    parse_conf_args "$@"
    write_ws_config
    return;
}

function run_action_remote_local_sync(){
    echo "run_action_remote_local_sync"
    return
}

function run_action_local_remote_sync(){
    echo "run_action_local_remote_sync"
    return;
}

function run_start(){
    echo "run_start"
    ws_cfg_file=$(get_ws_config_file)
    if [[ -z "$ws_cfg_file" ]];then
        echo "error on get configure"
        run_init
    fi
    . ${ws_cfg_file}
    echo ${local_dir}
    echo "$remote_dir"
    echo "$ssh_port"
    echo "$ssh_pass"
    echo "$ssh_acc"

    validate_ws_config
    # positional args
    args=()
    # named args
    while [[ "$1" != "" ]]; do
        case "$1" in
            -d | --daemon )                  daemon=true;  shift;;
           -h | --help )                     usage;          exit;; # quit and show usage
            * )                              args+=("$1")             # if no match, add it to the positional args
        esac
        shift # move to next kv pair
    done
    # restore positional args
    set -- "${args[@]}"
    watch_dir
}

# ws-rsync.sh init : you will run the initial steps for the current workspace dir"
# run the command bellow to update your configure which already done in initial step
# ws-rsync.sh config --ssh kevin@exampleserver --ssh-key $HOME/.ssh/examplekey ...
# After inital/configue then can use the script to run some action
# by default, the script will run the default action monitoring and sync the workspace
# with daemon options, then script will run in background for example
# ws-rsync.sh start --daemon  : workspace-rsync will monitor your configured workspace
# ws-rsync.sh stop : workspace-rsync will monitor your configured workspace
# when we think that remote side is latest version, then we need to sync up with remote site. In this case, that we will
# download the newer files from remote workspace
# ws-rsync.sh run remote-local-sync : run a sync up from local to remote: rsync download newer from remote to local/ scp download-replace everything from remote to local
# when we think that local side is latest version, then we need to update the newer files to remote workspace
# ws-rsync.sh run local-remote-sync : run a sync up from local to remote: rync  upload the newer from local to remote....
function run
{
    subcommand=$1
    action=$2
    case ${subcommand} in
    "" | "-h" | "--help")
        usage
        exit 0
        ;;
    "" | "init" )
        shift
        run_init
        exit 0
        ;;
    "" | "config" )
        shift
        run_configue $@
        exit 0
        ;;
    "" | "run")
    shift
    action=$1
    shift
    echo "run action: ${subcommand}_${action} $@"
    ${subcommand}_${action} $@
    if [[ $? = 127 ]]; then
            echo "Error: '$subcommand' is not a known subcommand." >&2
            echo "       Run '$ProgName --help' for a list of known subcommands." >&2
            exit 1
        fi
    ;;
    *)
        echo "Error: '$subcommand' is not a known subcommand." >&2
        echo "       Run '$ProgName --help' for a list of known subcommands." >&2
        exit 1
        ;;
esac
}

run "$@";