#!/bin/bash

# Load data from .env
source ../.env
private_address=$PRIVATE_VRSC_ADDRESS
public_address=$PUBLIC_VRSC_ADDRESS

verus_cli_dir=$HOME/verus-cli

echo ""
echo "-------------------- Send VRSC from z_addr to public_addr  --------------------"
echo ""
read -p "Enter z_address [${private_address}]: " z_address
if [ -z "${z_address}" ]
then
    z_address=$private_address
fi

echo ""

read -p "Enter public_address [${public_address}]: " pub_addr
if [ -z "${pub_addr}" ]
then
        pub_addr=$public_address
fi

echo ""

amount=$($verus_cli_dir/verus z_getbalance ${z_address})
read -p "Enter VRSC amount to unshield [all]: " amount
if [ -z "${amount}" ]
then
    amount=$($verus_cli_dir/verus z_getbalance ${z_address})
fi
# use 'bc' to treat vars as FLOATs (not or STRINGs). By default 0.123 is treated as STRING
# sudo apt install -y bc
fee=0.0001

# total amount including fee
amount_total=$(bc -l <<< "$amount - $fee" )
if [ ${amount} = "0.00000000" ]; then
    echo ""
    echo "!!!!!! VRSC balance on ${z_address} = 0.00000000 !!!!!!"
    echo ""

else
    echo ""
    echo "Sending ${amount_total} VRSC to ${pub_addr}..."
    echo ""
    $verus_cli_dir/verus z_sendmany ${z_address} "[{\"address\": \"${pub_addr}\" ,\"amount\": ${amount_total}}]"
fi

