#!/bin/bash

while [[ $# -gt 0 ]]; do 
  key="$1"
  case $key in 
    -v)
      shift
      VALIDATOR="$1"
      shift
      ;;
    -b)
      shift
      VALIDATORBECH="$1"
      shift
      ;;
    *)
      echo "[WARN] Unrecognized argument: $key"
      shift
    ;;
  esac
done

LCDHOST=${LCDHOST:=localhost}
LCDPORT=${LCDPORT:=1317}
[ -z $VALIDATOR ] && echo "[ERROR] Must provide your validator address (-v)" && echo "hint: find this value with this command on your validator node: terrad tendermint show-validator" && exit 1
[ -z $VALIDATORBECH ] && echo "[ERROR] Must provide your validator bech address (-b)" && echo "hint: find this value with this command whereever you validator address is stored: terracli keys show -a --bech val <walletname>" && exit 1


VALIDATOR=terravalconspub1zcjduepqvmsjtatpwg5yr4lsq296zudmvrr3ra9tln9paap2tmzg8sa0ytaqm5c428 #terrad tendermint show-validator
VALIDATORBECH=terravaloper1s5cyxwl36atv65m03pumrp9alhn2xdtzw5ug4l #terracli keys show -a --bech val <walletname>

# get moniker name
MONIKER=$(curl -s ${LCDHOST}:1317/staking/validators/${VALIDATORBECH} | jq '.result.description.moniker' -r)
echo; echo "[INFO] Checking on validator: $MONIKER"


# make sure we are not jailed
JAILED=$(curl -s ${LCDHOST}:1317/staking/validators/${VALIDATORBECH} | jq '.result.jailed' -r)
if [ ! "$JAILED" = "false" ]; then 
echo; echo "[WARN] You are not not jailed!  Run: curl -s ${LCDHOST}:1317/staking/validators/${VALIDATORBECH} |jq"
exit 1
fi


# how much is staked with us
STAKE=$(curl -s ${LCDHOST}:1317/staking/validators/${VALIDATORBECH} | jq '.result.tokens' -r)
echo; echo "$MONIKER has ${STAKE}uluna staked"


# how many blocks have we missed
MISSEDBLOCKS=$(curl -s ${LCDHOST}:1317/slashing/validators/${VALIDATOR}/signing_info| jq '.result.missed_blocks_counter' -r)
echo; echo "${MONIKER} has missed $MISSEDBLOCKS blocks during this slashing period"


# vote periods missed in this oracle slash window
MISSEDVOTES=$(curl -s ${LCDHOST}:1317/oracle/voters/${VALIDATORBECH}/miss |jq '.result' -r)
echo; echo "${MONIKER} has missed ${MISSEDVOTES} oracle votes during this slashing period"



# how much luna we got in rewards
ULUNARWDS=$(curl -s ${LCDHOST}:1317/distribution/validators/${VALIDATORBECH}/rewards |jq '.result | .[] | select(.denom == "uluna") | .amount' -r)
echo; echo "${MONIKER} has ${ULUNARWDS}uluna ready to be claimed"


