# ada-scripts

You will need to follow the offical documents to get the following files; `payment.addr`, `payment.skey`, `stake.skey`, `cold.skey`, `pool-registration.cert`, `delegation.cert`. If you already have them you can skip to registering your pool section. Otherwise follow the following instructions.

#### Create keys and addresses
[Creating keys and addresses](https://docs.cardano.org/projects/cardano-node/en/latest/stake-pool-operations/keys_and_addresses.html)



## registering your pool 
All you have to do is the following command 

`./pool-reg-crt.sh <payment.addr> <payment.skey> <stake.skey> <cold.skey> <pool-registration.cert> <delegation.cert>`

It will display all the txhashs and ask for the one that has stake + fee.  Then it will ask you for the fee (500ADA).  That's it.
