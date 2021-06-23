#!/bin/bash

email_to_notify="user@example.com"
service="verusd"
user_home_dir="/home/${USER}"
script_name="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
txcount_history_file="${user_home_dir}/txcount_hist.txt"
verus_logs_dir=${user_home_dir}/verus-logs

# If verusd is NOT running copy 'debug.log' file, send email and exit script.
if ! pgrep -x "$service" > /dev/null
then
    # Create verus-logs dir if not exist
    mkdir -p $verus_logs_dir
    # Copy last 'debug.log' file
    cp -u ${user_home_dir}/.komodo/VRSC/debug.log $verus_logs_dir/$(date +%Y%m%d%H%M)debug.log
    echo -e "The '$service' is not running.\nSend from script '$script_name'" | mail -s "Local wallet problem!" -a "From: ${USER}@$(hostname).local" $email_to_notify
    exit 1
fi

# Create txcount_hist.txt file if NOT exists or value stored in txcount_hist.txt file is NOT integer
if [ ! -f $txcount_history_file ] || ! [[ "$(cat ${txcount_history_file})" =~ ^[0-9]+$ ]]
then
    echo "0" > $txcount_history_file
fi

# Get txcount data
txcount_history=$(cat ${txcount_history_file})
txcount_current=$(${user_home_dir}/verus-cli/verus getwalletinfo | grep txcount | sed -r 's/.* ([0-9]+\.*[0-9]*).*?/\1/')

# If txcount_current variable is NOT integer send mail and exit script.
if ! [[ "$txcount_current" =~ ^[0-9]+$ ]]
then
    echo -e "The 'verusd' is running, but output for call 'verus getwalletinfo | grep txcount...' is not integer. \nSend from script '$script_name'" | mail -s "Local wallet problem!" -a "From: ${USER}@$(hostname).local" $email_to_notify
    exit 1
fi

# Check if txcount_current is bigger than last saved value.
if (($txcount_current > $txcount_history))
then
    # Update txcount_history
    echo $txcount_current > $txcount_history_file
    stakevalue=$(${user_home_dir}/verus-cli/verus getwalletinfo | grep immature_balance | awk '{print $2}' | sed 's/,$//')
    # Send email notification only when immature_balance is != 0
    if [[ $stakevalue != 0.00000000 ]]
    then
        echo "You have new tx in your VRSC wallet! -> $stakevalue VRSC" | mail -s "New tx in wallet" -a "From: ${USER}@$(hostname).local" $email_to_notify
    fi
else
    # For tests
    no_change="1"
fi
