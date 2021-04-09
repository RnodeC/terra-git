#/bin/sh


[ -z $NETWORK ] && echo "[ERROR] NETWORK is required.  Exiting." && exit 1

echo; echo "[INFO] Launching terra lcd server"
terracli rest-server \
	--chain-id=$NETWORK \
    --laddr=tcp://localhost:1317 \
    --node tcp://localterrad:26657 \
    --trust-node=false