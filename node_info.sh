#!/bin/bash
# Default variables
script_version="v5.0.0"
language="EN"
network="testnet"
raw_output="false"
keyring_backend=""

# Options
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/colors.sh) --
option_value(){ echo $1 | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script shows information about an Initia node"
		echo
		echo -e "Usage: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h,  --help               show help page"
		echo -e "  -l,  --language LANGUAGE  use the LANGUAGE for texts"
		echo -e "                            LANGUAGE is '${C_LGn}EN${RES}' (default), '${C_LGn}RU${RES}'"
		echo -e "  -kb, --keyring-backend    keyring's backend (by default ${C_LGn}parsing from the config${RES})"
		echo -e "  -m,  --mainnet            use the script in a mainnet"
		echo -e "  -ro, --raw-output         the raw JSON output"
		echo
		echo -e "You can use either \"=\" or \" \" as an option and value ${C_LGn}delimiter${RES}"
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "https://github.com/SecorD0/Initia/blob/main/node_info.sh - script URL"
		echo -e "         (you can send Pull request with new texts to add a language)"
		echo -e "https://t.me/OnePackage — noderun and tech community"
		echo
		return 0 2>/dev/null; exit 0
		;;
	-l*|--language*)
		if ! grep -q "=" <<< $1; then shift; fi
		language=`option_value $1`
		shift
		;;
	-kb*|--keyring-backend*)
		if ! grep -q "=" <<< $1; then shift; fi
		keyring_backend=`option_value $1`
		shift
		;;
	-m|--mainnet)
		network="mainnet"
		shift
		;;
	-ro|--raw-output)
		raw_output="true"
		shift
		;;
	*|--)
		break
		;;
	esac
done

# Config
daemon="`which initiad`"
token_name="init"
node_dir="$HOME/.initia/"
wallet_name="$initia_wallet_name"
wallet_address="$initia_wallet_address"
wallet_address_variable="initia_wallet_address"
validator_address="$initia_validator_address"
validator_address_variable="initia_validator_address"
if [ ! -n "$keyring_backend" ]; then
	keyring_backend=`$daemon config get client keyring-backend 2>/dev/null | tr -d '"'`
fi
sudo apt install jq bc -y &>/dev/null
if [ "$network" == "mainnet" ]; then
	global_rpc=""
	explorer_url_template=""
	current_block=`echo`
else
	global_rpc="https://initia-testnet-rpc.polkachu.com:443"
	explorer_url_template="https://scan.testnet.initia.xyz/initiation-1/validators/"
	current_block=`wget -qO- "${global_rpc}/abci_info" | jq -r ".result.response.last_block_height"`
fi

# Functions
printf_n(){ printf "$1\n" "${@:2}"; }
main() {
	# Texts
	if [ "$language" = "RU" ]; then
		local t_ewa="Для просмотра баланса кошелька необходимо добавить его в систему виде переменной, поэтому ${C_LGn}введите пароль от кошелька${RES}: "
		local t_ewa_err="${C_LR}Не удалось получить адрес кошелька!${RES}"
		local t_nn="\nНазвание ноды:              ${C_LGn}%s${RES}"		
		local t_net="Сеть:                       ${C_LGn}%s${RES}"
		local t_ni="ID ноды:                    ${C_LGn}%s${RES}"
		local t_nv="Версия ноды:                ${C_LGn}%s${RES}"
		local t_lb="Последний блок:             ${C_LGn}%s${RES}"
		local t_sy1="Нода синхронизирована:      ${C_LR}нет${RES}"
		local t_sy2="Осталось нагнать:           ${C_LR}%d-%d=%d (около %.2f мин.)${RES}"
		local t_sy3="Нода синхронизирована:      ${C_LGn}да${RES}"
		
		local t_va="\nАдрес валидатора:           ${C_LGn}%s${RES}"
		local t_eu="Страница в эксплорере:      ${C_LGn}%s${RES}"
		local t_vm="Название валидатора:        ${C_LGn}%s${RES}"
		local t_id="Keybase ключ:               ${C_LGn}%s${RES}"
		local t_si="Сайт:                       ${C_LGn}%s${RES}"
		local t_det="Описание:\n${C_LGn}%s${RES}"
		
		local t_pk="\nПубличный ключ валидатора:  ${C_LGn}%s${RES}"
		local t_nij1="Валидатор в тюрьме:         ${C_LR}да${RES}"
		local t_nij2="Валидатор в тюрьме:         ${C_LGn}нет${RES}"	
		local t_del="Делегировано токенов:       ${C_LGn}%.4f${RES} ${token_name}"
		local t_vp="Весомость голоса:           ${C_LGn}%.4f${RES}\n"
		
		local t_wa="Адрес кошелька:             ${C_LGn}%s${RES}"
		local t_bal="Баланс:                     ${C_LGn}%.4f${RES} ${token_name}\n"
	# Send Pull request with new texts to add a language - https://github.com/SecorD0/Initia/blob/main/node_info.sh
	#elif [ "$language" = ".." ]; then
	else
		local t_ewa="To view the wallet balance, you have to add it to the system as a variable, so ${C_LGn}enter the wallet password${RES}: "
		local t_ewa_err="${C_LR}Failed to get the wallet address!${RES}"
		local t_nn="\nMoniker:                 ${C_LGn}%s${RES}"		
		local t_net="Network:                 ${C_LGn}%s${RES}"
		local t_ni="Node ID:                 ${C_LGn}%s${RES}"
		local t_nv="Node version:            ${C_LGn}%s${RES}"
		local t_lb="Latest block height:     ${C_LGn}%s${RES}"
		local t_sy1="Node is synchronized:    ${C_LR}no${RES}"
		local t_sy2="It remains to catch up:  ${C_LR}%d-%d=%d (about %.2f min.)${RES}"
		local t_sy3="Node is synchronized:    ${C_LGn}yes${RES}"
		
		local t_va="\nValidator address:       ${C_LGn}%s${RES}"
		local t_eu="Page in explorer:        ${C_LGn}%s${RES}"
		local t_vm="Validator moniker:       ${C_LGn}%s${RES}"
		local t_id="Keybase key:             ${C_LGn}%s${RES}"
		local t_si="Website:                 ${C_LGn}%s${RES}"
		local t_det="Details:\n${C_LGn}%s${RES}"
		
		local t_pk="\nValidator public key:    ${C_LGn}%s${RES}"
		local t_nij1="Validator in a jail:     ${C_LR}yes${RES}"
		local t_nij2="Validator in a jail:     ${C_LGn}no${RES}"
		local t_del="Delegated tokens:        ${C_LGn}%.4f${RES} ${token_name}"
		local t_vp="Voting power:            ${C_LGn}%.4f${RES}\n"
		
		local t_wa="Wallet address:          ${C_LGn}%s${RES}"
		local t_bal="Balance:                 ${C_LGn}%.4f${RES} ${token_name}\n"
	fi
	
	# Actions
	if [ -n "$wallet_name" ] && ([ ! -n "$wallet_address" ] || [ ! -n "$validator_address" ]); then
		printf "$t_ewa"
		local password
		read password
		local wallet_address=`echo "$password" | $daemon keys show "$wallet_name" --keyring-backend "$keyring_backend" -a 2>/dev/null`
		if [ -n "$wallet_address" ]; then
			local validator_address=`echo "$password" | $daemon keys show "$wallet_name" --keyring-backend "$keyring_backend" -a --bech val`
			. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n "$wallet_address_variable" -v "$wallet_address"
			. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n "$validator_address_variable" -v "$validator_address"
		else
			printf_n "$t_ewa_err"
		fi
		unset password
	fi
	
	local local_rpc=`grep -oPm1 "(?<=^laddr = \")([^%]+)(?=\")" "${node_dir}config/config.toml"`
	local status=`$daemon status --node "$local_rpc" 2>&1`
	local moniker=`jq -r ".node_info.moniker" <<< "$status"`
	local node_info=`$daemon query mstaking validators --node "$local_rpc" --limit 10000 -oj 2>/dev/null | jq -r '.validators[] | select(.operator_address=='\"$validator_address\"')'`
	local network=`jq -r ".node_info.network" <<< "$status"`
	local node_id=`jq -r ".node_info.id" <<< "$status"`
	local node_version=`$daemon version 2>&1 | tr -d '"'`
	local latest_block_height=`jq -r ".sync_info.latest_block_height" <<< "$status"`
	local catching_up=`jq -r ".sync_info.catching_up" <<< "$status"`
	
	if [ -n "$validator_address" ]; then
		local explorer_url="${explorer_url_template}${validator_address}"
	fi
	if [ -n "$node_info" ]; then
		local validator_moniker=`jq -r ".description.moniker" <<< "$node_info"`
		local identity=`jq -r ".description.identity" <<< "$node_info"`
		local website=`jq -r ".description.website" <<< "$node_info"`
		local details=`jq -r ".description.details" <<< "$node_info"`
		local validator_pub_key=`$daemon tendermint show-validator | tr "\"" "'"`
		local jailed=`jq -r ".jailed" <<< "$node_info"`
		if [ ! -n "$jailed" ]; then
			local jailed="false"
		fi

		local delegated=`bc -l <<< "$(jq -r '.tokens[] | select(.denom=="uinit") | .amount' <<< "$node_info")/1000000" 2>/dev/null`
	fi
	local voting_power=`jq -r ".validator_info.voting_power" <<< "$status"`
	
	if [ -n "$wallet_address" ]; then
		if [ "$catching_up" = "false" ] || ! grep -q ":" <<< "$balance_rpc"; then
			local balance_rpc="$local_rpc"
		fi
		local balance=`bc -l <<< "$($daemon query bank balances "$wallet_address" -oj --node "$balance_rpc" 2>/dev/null | jq -r ".balances[0].amount")/1000000" 2>/dev/null`
	fi
	
	# Output
	if [ "$raw_output" = "true" ]; then
		printf_n '{"moniker": "%s", "network": "%s", "node_id": "%s", "node_version": "%s", "latest_block_height": %d, "catching_up": %b, "validator_address": "%s", "explorer_url": "%s", "validator_moniker": "%s", "identity": "%s", "website": "%s", "details": "%s", "validator_pub_key": "%s", "jailed": %b, "delegated": %.4f, "voting_power": %.4f, "wallet_address": "%s", "balance": %.4f}' \
"$moniker" \
"$network" \
"$node_id" \
"$node_version" \
"$latest_block_height" \
"$catching_up" \
"$validator_address" \
"$explorer_url" \
"$validator_moniker" \
"$identity" \
"$website" \
"$details" \
"$validator_pub_key" \
"$jailed" \
"$delegated" \
"$voting_power" \
"$wallet_address" \
"$balance" 2>/dev/null
	else
		printf_n "$t_nn" "$moniker"		
		printf_n "$t_net" "$network"
		printf_n "$t_ni" "$node_id"
		printf_n "$t_nv" "$node_version"
		printf_n "$t_lb" "$latest_block_height"
		if [ "$catching_up" = "true" ]; then
			local diff=`bc -l <<< "$current_block-$latest_block_height"`
			local takes_time=`bc -l <<< "$diff/60"`
			printf_n "$t_sy1"
			printf_n "$t_sy2" "$current_block" "$latest_block_height" "$diff" "$takes_time"
		else
			printf_n "$t_sy3"
		fi
		
		printf_n "$t_va" "$validator_address"
		printf_n "$t_eu" "$explorer_url"
		printf_n "$t_vm" "$validator_moniker"
		printf_n "$t_id" "$identity"
		printf_n "$t_si" "$website"
		printf_n "$t_det" "$details"
		
		printf_n "$t_pk" "$validator_pub_key"
		if [ "$jailed" = "true" ]; then
			printf_n "$t_nij1"
		else
			printf_n "$t_nij2"
		fi
		printf_n "$t_del" "$delegated"
		printf_n "$t_vp" "$voting_power"
		
		if [ -n "$wallet_address" ]; then
			printf_n "$t_wa" "$wallet_address"
			printf_n "$t_bal" "$balance"
		fi
	fi
}

main
