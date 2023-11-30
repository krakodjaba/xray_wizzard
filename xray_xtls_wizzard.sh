#!/bin/bash



# Запрос обновления пакетов

read -p "Хотите обновить пакеты? (y/n): " update_packages



if [ "$update_packages" == "y" ]; then

  # Обновление пакетов

  apt update && apt full-upgrade -y

fi



# Запрос установки необходимых пакетов

read -p "Хотите установить необходимые пакеты? (y/n): " install_packages



if [ "$install_packages" == "y" ]; then

  # Установка необходимых пакетов

  apt install wget unzip sudo jq -y

fi



# Скачивание Xray

wget https://github.com/XTLS/Xray-core/releases/download/v1.8.1/Xray-linux-64.zip



# Распаковка архива и установка Xray

mkdir /opt/xray

unzip ./Xray-linux-64.zip -d /opt/xray

chmod +x /opt/xray/xray



# Создание конфигурационного файла

echo '{

  "log": {

    "loglevel": "info"

  },

  "routing": {

    "rules": [],

    "domainStrategy": "AsIs"

  },

  "inbounds": [

    {

      "port": 23,

      "tag": "ss",

      "protocol": "shadowsocks",

      "settings": {

        "method": "2022-blake3-aes-128-gcm",

        "password": "aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb",

        "network": "tcp,udp"

      }

    },

    {

      "port": 443,

      "protocol": "vless",

      "tag": "vless_tls",

      "settings": {

        "clients": [

          {

            "id": "4c3fe585-ac09-41df-b284-70d3fbe18884",

            "email": "user1@myserver",

            "flow": "xtls-rprx-vision"

          }

        ],

        "decryption": "none"

      },

      "streamSettings": {

        "network": "tcp",

        "security": "reality",

        "realitySettings": {

          "show": false,

          "dest": "www.microsoft.com:443",

          "xver": 0,

          "serverNames": [

            "www.microsoft.com"

          ],

          "privateKey": "GOTPj_klK7_j_IvjxiCtyBL80RYotYSOdBBBSfFOMH4",

          "minClientVer": "",

          "maxClientVer": "",

          "maxTimeDiff": 0,

          "shortIds": [

            "aabbccdd"

          ]

        }

      },

      "sniffing": {

        "enabled": true,

        "destOverride": [

          "http",

          "tls"

        ]

      }

    }

  ],

  "outbounds": [

    {

      "protocol": "freedom",

      "tag": "direct"

    },

    {

      "protocol": "blackhole",

      "tag": "block"

    }

  ]

}' > "/opt/xray/config.json"


# Запрос количества пользователей

read -p "Введите количество пользователей для конфигурации Xray: " user_count

# Проверка на число

if ! [[ "$user_count" =~ ^[0-9]+$ ]]; then

  echo "Ошибка: Введите корректное число пользователей."

  exit 1

fi

# Генерация UUID и обновление конфигурационного файла

config_file="/opt/xray/config.json"

# Удаление старых клиентов из конфигурации
config_file="/opt/xray/config.json"
jq 'del(.inbounds[1].settings.clients[])' "$config_file" > temp_config.json && mv temp_config.json "$config_file"

for ((i=1; i<=user_count; i++)); do

  user_uuid=$(/opt/xray/xray uuid)

  user_config='{

      "id": "'"$user_uuid"'",

      "email": "user'"$i"'@myserver",

      "flow": "xtls-rprx-vision"

  }'

  # Добавление пользователя в конфигурацию

  jq --argjson user_config "$user_config" '.inbounds[1].settings.clients += [$user_config]' "$config_file" --tab > temp_config.json && mv temp_config.json "$config_file"

done

# Генерация x25519 ключей
private_key=$(/opt/xray/xray x25519 | awk '/Private key:/ {print $NF}')
public_key=$(/opt/xray/xray x25519 | awk '/Public key:/ {print $NF}')
echo "Публичный ключ: $public_key"
# Обновление конфигурационного файла с private key
jq --arg private_key "$private_key" '.inbounds[1].streamSettings.realitySettings |= . + { "privateKey": $private_key }' "$config_file" > temp_config.json && mv temp_config.json "$config_file"

# Запрос варианта выбора для dest и serverNames

options=("www.samsung.com:443" "www.googletagmanager.com:443" "www.asus.com:443" "www.amd.com:443" "www.cisco.com:443" "www.microsoft.com:443" "dl.google.com:443" "www.linksys.com:443" "www.nvidia.com:443" "manual_input")

PS3="Выберите вариант dest и serverNames (или введите 'manual_input' для ручного ввода): "

select option in "${options[@]}"; do

  case "$option" in

    "manual_input")

      read -p "Введите значение dest: " dest_value

      read -p "Введите значение serverNames: " server_names_value

      break

      ;;

    *)

      dest_value=$(echo $option | cut -d: -f1)

      server_names_value=$(echo $option | cut -d. -f2-)

      break

      ;;

  esac

done



# Обновление конфигурационного файла с выбранными dest и serverNames

jq --arg dest "$dest_value" --arg server_names "$server_names_value" '.inbounds[1].streamSettings.realitySettings.dest = $server_names | .inbounds[1].streamSettings.realitySettings.serverNames = [$dest]' "$config_file" --tab > temp_config.json && mv temp_config.json "$config_file"



# Генерация случайных данных для shortIds

short_ids=$(openssl rand -hex 8)



# Обновление конфигурационного файла с shortIds

jq --arg short_ids "$short_ids" '.inbounds[1].streamSettings.realitySettings.shortIds = [$short_ids]' "$config_file" --tab > temp_config.json && mv temp_config.json "$config_file"


# Опционально: Добавление правила в брандмауэр (если это требуется)

# iptables -A INPUT -p tcp --dport 443 -j ACCEPT



echo "Установка завершена."

echo "Открытый ключ x25519: $public_key"

