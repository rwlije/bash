#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

NUBIT_DIR="$HOME/nubit-node"
NKEY_BIN="$NUBIT_DIR/bin/nkey"
MNEMONIC_FILE="$NUBIT_DIR/mnemonic.txt"
DIRS=("$HOME/nubit-node" "$HOME/.nubit-light-nubit-alphatestnet-1")
NUBIT_BIN="$NUBIT_DIR/bin/nubit"

while true; do
	echo -e ''
	echo -e '██╗░░██╗░█████╗░██████╗░██████╗░'
	echo -e '╚██╗██╔╝██╔══██╗██╔══██╗██╔══██╗'
	echo -e '░╚███╔╝░███████║██████╔╝██║░░██║'
	echo -e '░██╔██╗░██╔══██║██╔══██╗██║░░██║'
	echo -e '██╔╝╚██╗██║░░██║██║░░██║██████╔╝'
	echo -e '╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░'
	echo -e ''

	echo -e "1. Установить ноду Nubit"
	echo -e "2. Вывести информацию о ноде"
	echo -e "3. Посмотреть логи"
	echo -e "4. Проверить работоспособность ноды"
	echo -e "5. Удалить ноду"
	echo -e ''
	read -p "Выберите опцию: " choice

	case $choice in
		1)
			echo -e "${GREEN}Начинаем установку ноды...${NC}"
			
			echo -e "${GREEN}Обновляем пакеты...${NC}"
			if sudo apt update && sudo apt upgrade -y; then
				echo -e "${GREEN}Обновление пакетов завершено${NC}"
			else
				echo -e "${RED}При обновлении пакетов произошла ошибка${NC}"
				exit 1
			fi
			
			echo -e "${GREEN}Устанавливаем дополнительные пакеты...${NC}"
			if sudo apt install curl git wget build-essential jq screen -y; then
				echo -e "${GREEN}Установка дополнительных пакетов завершена${NC}"
			else
				echo -e "${RED}При установке дополнительных пакетов произошла ошибка${NC}"
				exit 1
			fi
			
			echo -e "${GREEN}Создаем новый сеанс...${NC}"
			if screen -dmS nubit bash -c "curl -sL1 https://nubit.sh | bash"; then
				echo -e "${GREEN}Нода скоро будет запущена${NC}"
			else
				echo -e "${RED}При создании нового сеанса произошла ошибка${NC}"
			fi
			;;

		2)
			echo -e "${GREEN}Выводим информацию о ноде...${NC}"
			
			if [ ! -f "$MNEMONIC_FILE" ]; then
				echo -e "${RED}Нужные файлы не найдены${NC}"
				echo -e "${RED}Если вы уже установили ноду - просто подождите несколько минут${NC}"
			else
				SEED_PHRASE=$(cat "$MNEMONIC_FILE")
				PUBKEY=$($NKEY_BIN list --p2p.network nubit-alphatestnet-1 --node.type light | grep 'pubkey:' | awk -F'"key":' '{print $2}' | awk -F'"' '{print $2}')
				ADDRESS=$($NKEY_BIN list --p2p.network nubit-alphatestnet-1 --node.type light | grep 'address:' | awk -F': ' '{print $2}')
				
				echo -e "${GREEN}Мнемоническая фраза:${NC} $SEED_PHRASE"
				echo -e "${GREEN}Публичный ключ:${NC} $PUBKEY"
				echo -e "${GREEN}Адрес:${NC} $ADDRESS"
			fi
			;;

		3)
			echo -e "${GREEN}Открываем логи...${NC}"
			
			if screen -ls | grep -q "\.nubit"; then
				screen -r nubit
			else
				echo -e "${RED}Сессия nubit не существует${NC}"
			fi
			;;

		4)
			echo -e "${GREEN}Проверяем работоспособность ноды...${NC}"
			
			dirs_exist=true
			for dir in "${DIRS[@]}"; do
				if [ ! -d "$dir" ]; then
					dirs_exist=false
				fi
			done

			if [ "$dirs_exist" = true ]; then
				$NUBIT_BIN das sampling-stats --node.store "$HOME/.nubit-light-nubit-alphatestnet-1"
			else
				echo -e "${RED}Нода не найдена${NC}"
				echo -e "${RED}Если вы только что установили ноду, подождите пару минут${NC}"
			fi
			;;

		5)
			read -p "Вы уверены, что хотите удалить ноду? (y/n): " confirm
			
			if [ "$(echo "$confirm" | tr '[:upper:]' '[:lower:]')" = "y" ]; then
				screen_id=$(screen -ls | grep 'nubit' | awk '{print $1}' | sed 's/.$//') 
		  
				if [ -n "$screen_id" ]; then
					echo -e "${GREEN}Завершаем сессию...${NC}"
					screen -XS "$screen_id" quit
					echo -e "${GREEN}Сессия nubit завершена${NC}"
				else
					echo -e "${RED}Сессия nubit не найдена${NC}"
				fi
				
				dirs_exist=true
				for dir in "${DIRS[@]}"; do
					if [ ! -d "$dir" ]; then
						dirs_exist=false
					fi
				done

				if [ "$dirs_exist" = true ]; then
					echo -e "${GREEN}Удаляем ноду...${NC}"
					for dir in "${DIRS[@]}"; do
						rm -rf "$dir"
					done
					echo -e "${GREEN}Нода удалена${NC}"
				else
					echo -e "${RED}Нода не найдена${NC}"
				fi
			fi
			;;
			
	esac
done
