#!/bin/bash

# Get ../.env file
env_dir="$(dirname "$(dirname "$(readlink -fm "$0")")")"
env_file=$env_dir/.env

if [ ! -f "$env_file" ]
then
    echo "File ${env_file} not exists!"
    exit 1
fi
# Load data from .env
source "$env_file"
email_to_notify=$EMAIL_TO_NOTIFY
email_notification=$EMAIL_NOTIFICATION

# Exit script if '$email_notification' var is different than "on" or not assigned.
if [ -z "$email_notification" ] || [ "$email_notification" != "on" ]
then
    exit 1
fi

service="verusd"
user_home_dir=$HOME
script_name=$(basename $(realpath "$0"))
# File 'tx_history_file' contains historical wallet transactions (tx) data:
# - 'txid_stake_previous' - most recent STAKE ("mint") transaction id (txid) from wallet
# - 'txcount_previous' - recent wallet transactions count (txcount)
tx_history_file="${user_home_dir}/tx_hist.json"
verus_logs_dir=${user_home_dir}/verus-logs
verus_debug_log=${user_home_dir}/.komodo/VRSC/debug.log
verus_cli=${user_home_dir}/verus-cli/verus

# Function sends email msg to email address specified in '$email_to_notify' var.
send_email () {
    local email_subject=$1
    local email_body=$2
    echo -e "${email_body}" | mail -s "${email_subject}" $email_to_notify
}

# Function deletes 'debug.log' files older than 60 minutes except the last log.
remove_old_log_files () {
    find $verus_logs_dir -type f -name "*debug.log" -printf '%T@\t%p\n' | sort -t $'\t' -g | head -n -1 | awk '{print $2}' | xargs -I{} find '{}' -mmin +60 -delete
}

# Function calculate MD5 hash of specified file.
get_md5_checksum (){
  md5sum "$1" 2> /dev/null | awk '{ print $1 }'
}

# If verusd is NOT running copy 'debug.log' file, send email and exit script.
if ! pgrep -x "$service" > /dev/null
then
    # Create verus-logs dir if not exist
    mkdir -p $verus_logs_dir
    # Archive last VRSC 'debug.log' file. Do not copy if that log file already exist in '$verus_logs_dir'
    md5_verus_debug_log=$(get_md5_checksum $verus_debug_log)
    # Find most recent '*debug.log' file in '$verus_logs_dir'
    verus_debug_log_last=$(find $verus_logs_dir -type f -iname '*debug.log' -printf "%T@ %p\n" | sort -n | cut -d' ' -f 2- | tail -n 1)
    md5_verus_debug_log_last=$(get_md5_checksum $verus_debug_log_last)
    # Copy the 'debug.log' only if MD5 hashes of most recent '*debug.log' and 'debug.log' are different.
    if [ "$md5_verus_debug_log" != "$md5_verus_debug_log_last" ]
    then
        cp -u $verus_debug_log $verus_logs_dir/$(date +%Y%m%d%H%M)debug.log
    fi
    send_email "Local wallet problem!" "The '$service' is not running.\nSend from script '$script_name'"
    remove_old_log_files
    exit 1
fi

# Remove old logs if 'verus_logs_dir' exists.
if [ -d "$verus_logs_dir" ]
then
    remove_old_log_files
fi

# Create brand-new JSON file ('$tx_history_file') if NOT exists OR value stored with 'txcount_previous' key is NOT integer AND
# 'txid_stake_previous' key does not exist.
if [ ! -f ${tx_history_file} ] || ! [[ "$(jq -r '.txcount_previous' ${tx_history_file})" =~ ^[0-9]+$ && "$(jq -r '.' ${tx_history_file} | jq 'has("txid_stake_previous")')" == "true" ]]
then
    jq -n '{txid_stake_previous: "", txcount_previous: "0"}' > $tx_history_file
fi

# Get 'txcount' data
txcount_history=$(jq -r '.txcount_previous' ${tx_history_file})
txcount_current=$(${verus_cli} getwalletinfo | jq -r '.txcount')

# If '$txcount_current' var is NOT integer send email and exit script.
if ! [[ "$txcount_current" =~ ^[0-9]+$ ]]
then
    send_email "Local wallet problem!" "The 'verusd' is running, but output for call 'verus getwalletinfo | jq -r '.txcount'' is not integer. \nSend from script '$script_name'"
    exit 1
fi

# Check if '$txcount_current' is bigger than last saved value (test an arithmetic expression).
if (($txcount_current > $txcount_history))
then
    # Update 'txcount_previous' data  - jq does not support update original JSON file in place (.tmp file has been used)
    cat $tx_history_file | jq --arg txcount_previous "$txcount_current" '.txcount_previous |= $txcount_previous' > ${tx_history_file}.tmp && mv ${tx_history_file}.tmp ${tx_history_file}
    immature_balance=$(${verus_cli} getwalletinfo | jq -r '.immature_balance')
    # Send email notification only when immature_balance is != 0
    if [[ $immature_balance != 0 ]]
    then
        # Get VRSC amount of last STAKE transaction (tx) - under the hood below command get VRSC amount of the most recent STAKE ("mint") tx from the last 30 wallet txs
        stake_value=$(${verus_cli} listtransactions "*" 30 | jq -r '[.[]|select(.category=="mint")]|.[-1].amount')
        send_email "New STAKE in wallet" "You have new STAKE in your VRSC wallet! -> ${stake_value} VRSC"
    fi
fi
