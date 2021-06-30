#!/bin/bash

verus_cli_dir=$HOME/verus-cli

echo ""
echo "-------------------- getmininginfo --------------------"
$verus_cli_dir/verus getmininginfo
echo ""
echo "-------------------- getgenerate --------------------"
$verus_cli_dir/verus getgenerate

