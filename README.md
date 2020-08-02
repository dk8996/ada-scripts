# ada-scripts

You will need to follow the offical documents to get the following files

Start here to create the stake pool keys
[Creating keys and addresses](https://docs.cardano.org/projects/cardano-node/en/latest/stake-pool-operations/keys_and_addresses.html)

All you have to do is the following command 

`./pool-reg-crt.sh <payment.addr> <payment.skey> <stake.skey> <cold.skey> <pool-registration.cert> <delegation.cert>`

It will display all the txhashs and ask for the one that has stake + fee.  Then it will ask you for the fee (500ADA).  That's it.
