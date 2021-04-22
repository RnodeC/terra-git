#!/bin/bash

function usage() {
    echo "
    Usage - valcheck -m <moniker name> [OPTIONS]
    
    OPTIONS
    -l: LCD Host.  defaults to localhost
    -p: LCD Port.  defaults to 1317
    "
}

while [[ $# -gt 0 ]]; do 
  key="$1"
  case $key in 
    -h)
      shift
      usage
      echo
      exit 0
      ;;
    -m)
      shift
      MONIKER="$1"
      shift
      ;;
    -l)
      shift
      LCDHOST="$1"
      shift
      ;;
    -p)
      shift
      LCDPORT="$1"
      shift
      ;;
    *)
      echo "[WARN] Unrecognized argument: $key"
      shift
    ;;
  esac
done



# default lcd values - assuming localhost.  (I like to ssh port forward client to validator or sentry's lcd)
LCDHOST=${LCDHOST:=localhost}
LCDPORT=${LCDPORT:=1317}

[ -z $MONIKER ] && echo "[ERROR] Must provide moniker name (-m)" && usage && exit 1


# get addresses from moniker
CONSENSUS_PUBKEY=$(curl -s ${LCDHOST}:${LCDPORT}/staking/validators | jq --arg moniker "$MONIKER" '.result | .[] | select (.description.moniker == $moniker) | .consensus_pubkey' -r)
VALIDATORBECH=$(curl -s ${LCDHOST}:${LCDPORT}/staking/validators | jq --arg moniker "$MONIKER" '.result | .[] | select (.description.moniker == $moniker) | .operator_address' -r)

[ -z $CONSENSUS_PUBKEY ] && echo "[ERROR] CONSENSUS_PUBKEY not found" && usage && exit 1
[ -z $VALIDATORBECH ] && echo "[ERROR] VALIDATORBECH not found" && usage && exit 1

echo; echo "[INFO] Checking on validator: $MONIKER"
echo -e "\tCONSENSUS_PUBKEY: $CONSENSUS_PUBKEY"
echo -e "\tOPERATOR_ADDRESS: $VALIDATORBECH"


# make sure we are not jailed
JAILED=$(curl -s ${LCDHOST}:${LCDPORT}/staking/validators/${VALIDATORBECH} | jq '.result.jailed' -r)
if [ ! "$JAILED" = "false" ]; then 
echo; echo "[WARN] You are not not jailed!  Run: curl -s ${LCDHOST}:${LCDPORT}/staking/validators/${VALIDATORBECH} |jq"
exit 1
fi

# how much is staked with us
STAKE=$(curl -s ${LCDHOST}:${LCDPORT}/staking/validators/${VALIDATORBECH} | jq '.result.tokens' -r)
echo; echo "$MONIKER has ${STAKE}uluna staked"

# how many blocks have we missed
MISSEDBLOCKS=$(curl -s ${LCDHOST}:${LCDPORT}/slashing/validators/${CONSENSUS_PUBKEY}/signing_info| jq '.result.missed_blocks_counter' -r)
echo; echo "${MONIKER} has missed $MISSEDBLOCKS blocks during this slashing period"

# vote periods missed in this oracle slash window
MISSEDVOTES=$(curl -s ${LCDHOST}:${LCDPORT}/oracle/voters/${VALIDATORBECH}/miss |jq '.result' -r)
echo; echo "${MONIKER} has missed ${MISSEDVOTES} oracle votes during this slashing period"

# how much luna we got in rewards
ULUNARWDS=$(curl -s ${LCDHOST}:${LCDPORT}/distribution/validators/${VALIDATORBECH}/rewards |jq '.result | .[] | select(.denom == "uluna") | .amount' -r)
echo; echo "${MONIKER} has ${ULUNARWDS}uluna ready to be claimed"


