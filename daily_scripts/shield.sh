#!/bin/bash

# Load data from .env
source ../.env
private_address=$PRIVATE_VRSC_ADDRESS

verus_cli_dir=$HOME/verus-cli

$verus_cli_dir/verus z_shieldcoinbase "*" $private_address
