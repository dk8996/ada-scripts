#!/bin/bash

#title           :pool-reg-crt.sh
#donations       :ADA: addr1q832gesdnxn9twyymtqmqywcsutmqc23u6wghr5y44mmyn6dze685vgkuem8hvd3kdej7kpzuzf7wxk3qndrmwjplusq5rr3d6
#description     :This script makes it easy to register your pool, see https://docs.cardano.org/projects/cardano-node/en/latest/stake-pool-operations/register_stakepool.html.
#author		 :Dimitry Kudryavtsev (dimitry@mentful.com)
#version         :1
#usage		 :./pool-reg-crt.sh <payment.addr> <payment.skey> <stake.skey> <cold.skey> <pool-registration.cert> <delegation.cert>
#notes		 :For updates, please look at 
#==============================================================================


ONE_M=1000000
if [ $# -eq 6 ]; then
    echo "Your command line contains $# arguments"
else
    echo "Error: Your command line contains no arguments"
    exit 1
fi

echo "Environment Variables"
echo "Path: $PATH"
echo "User: $USER"
echo "=============="

file_check_exit() {
    local FILE=$1
    if [ -f "$FILE" ]; then
        echo "$FILE exists."
    else
        echo "Error: $FILE does not exist."
        exit 1
    fi
}

tx_table(){
  local count=-2
  local table
  local col=$1

  while read line; do
     count=$((count+1))
     tx_row=(`echo $line | cut -d " "  --output-delimiter=" " -f 1-`)
     local adaAmount=$((tx_row[2]/ONE_M))
     if [ $count -eq $1 ]; then
        echo "Selected --- $line --- $adaAmount"
	return 0
     fi
  done
}

get_tx_result(){
  count=0
  while read line; do
     if [ $count -gt 1 ]; then
         echo "$((count-1)) --- $line"
     fi
     count=$((count+1))
     #echo "Line: $line"
     #arr=(`echo $line | cut -d " "  --output-delimiter=" " -f 1-`)
     #echo ${arr[@]}
  done
}


file_check_exit $1
file_check_exit $2
file_check_exit $3
file_check_exit $4
file_check_exit $5
file_check_exit $6

FROM_PATH_PAYMENT_ADDR=$1
FROM_PATH_PAYMENT_KEY=$2
PATH_STAKE_SKEY=$3
PATH_COLD_SKEY=$4

PATH_POOL_REG_CERT=$5
PATH_DEL_CERT=$6

echo "FROM payment.addr file path: $FROM_PATH_PAYMENT_ADDR"
echo "payment.skey file path: $FROM_PATH_PAYMENT_KEY"
echo "stake.skey file path: $PATH_STAKE_SKEY"
echo "cold.skey file path: $PATH_COLD_SKEY"

echo "pool-registration.cert file path: $PATH_POOL_REG_CERT"
echo "delegation.cert file path: $PATH_DEL_CERT="

echo "Create protocol.json"
cardano-cli shelley query protocol-parameters \
  --mainnet \
  --out-file protocol.json

cardano-cli shelley query utxo \
  --address $(cat $FROM_PATH_PAYMENT_ADDR) \
  --mainnet

echo " "
read -p "Select one TxHash that has you'r stake + fee (500 ADA) [1 to ..] (the first TxHash is 1, second TxHash 2, ...)? ? " txhash_num
echo " "
tx_table < <(cardano-cli shelley query utxo \
  --address $(cat $FROM_PATH_PAYMENT_ADDR) \
  --mainnet) $txhash_num

tx_hash=${tx_row[0]}
tx_tx=${tx_row[1]}
tx_balance=${tx_row[2]}

echo "Selected TxHash: $tx_hash"
adaAmount=$((tx_row[2]/ONE_M))
echo "Selected Amount: $tx_balance Lovelace, $adaAmount ADA"


cardano-cli shelley transaction build-raw \
--tx-in "$tx_hash#$tx_tx" \
--tx-out $(cat $FROM_PATH_PAYMENT_ADDR)+0 \
--ttl 0 \
--fee 0 \
--out-file tx.draft \
--certificate-file $PATH_POOL_REG_CERT \
--certificate-file $PATH_DEL_CERT

echo " "

fee_text=$(cardano-cli shelley transaction calculate-min-fee \
--tx-body-file tx.draft \
--tx-in-count 1 \
--tx-out-count 1 \
--witness-count 3 \
--byron-witness-count 0 \
--mainnet \
--protocol-params-file protocol.json)

echo "Fee will be: $fee_text"

fee_text_arr=(`echo $fee_text | cut -d " "  --output-delimiter=" " -f 1-`)
fee=${fee_text_arr[0]}

pool_dep_text=$(cat protocol.json | grep "poolDeposit")

pool_dep_text_arr=(`echo $pool_dep_text | cut -d ":"  --output-delimiter=" " -f 1-`)
echo $pool_dep_text

max_amount=$(((tx_balance-fee)/ONE_M))
echo " "
read -p "Pool deposit amount, normally 500 ADA, in (ADA)? " send_amount_ada
echo " "

send_amount=$((send_amount_ada*ONE_M))
change_send_back=$((tx_balance - fee - send_amount))
change_send_back_ada=$((change_send_back/ONE_M))

echo "Change Back: $change_send_back Lovelace, $change_send_back_ada ADA"

tip_text=$(cardano-cli shelley query tip --mainnet)
tip_text_arr=(`echo $tip_text | cut -d ","  --output-delimiter=" " -f 1-`)

slotNo=${tip_text_arr[6]}
ttl=$((slotNo+200))

echo " "
echo "Current Slot: $slotNo, Setting ttl to: $ttl"
from_addr=$(cat $FROM_PATH_PAYMENT_ADDR)

echo " "

echo "Send: $send_amount_ada (ADA)"
echo "From address: $from_addr"

cardano-cli shelley transaction build-raw \
--tx-in "$tx_hash#$tx_tx" \
--tx-out "$from_addr+$change_send_back" \
--ttl $ttl \
--fee $fee \
--out-file tx.raw \
--certificate-file $PATH_POOL_REG_CERT \
--certificate-file $PATH_DEL_CERT


cardano-cli shelley transaction sign \
--tx-body-file tx.raw \
--signing-key-file $FROM_PATH_PAYMENT_KEY \
--signing-key-file $PATH_STAKE_SKEY \
--signing-key-file $PATH_COLD_SKEY \
--mainnet \
--out-file tx.signed
