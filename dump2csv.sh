#!/bin/bash
# Program:
#   dump2csv
#   使用mysqldump导出sql.gz文件
#
# v0.2.0 by alex.zhao 2021/03/24
####################################################

# init
USER=""
SOCKET=""
HOST=""
PORT=""
DB=""
TB=""
FILE=""
SQL=""

# Help Screen
function help() {
    echo -n "$0 [OPTIONS] -u UserName --host 192.168.0.1
Bash utility for dumping databases from remote host and localhost
GitHub Project:
  https://github.com/SisyphusSQ/autodump-mysql
Options:  
  -u|--user 	  Database user name
  -S|--socket 	Database socket
  -h|--host 	  Database host
  -P|--port   	Database port
  -D|--databaes Database name
  -T|--table 	  Database table name
  -f|--file 	  output file and its full path
  --sql         query sql
"
}

# check password
function ckPwd () {
    # import password
    read -s -rp "Enter Password:" PWD
    printf "\n"

    if ! mysql "$USER" -p"$PWD" $SOCKET $HOST $PORT -e "select @@version;" >/dev/null; 
    then
        printf "[Err] 密码错误\n" && exit 1
    fi
}

function dumpCsv() {
    if [ "$SQL" = "" ]; then
        # table2csv
        # count rows
        read -rp "Do you want to count table $TB rows(y/n):" answer

        if [ "$answer" = "y" ]; then
            ROWS=$(mysql "$USER" -p"$PWD" $SOCKET $HOST $PORT -e "SELECT count(*) FROM $DB.$TB" | grep -E "^[0-9]+")
            printf "%s的总行数: %s \n" "$TB" "$ROWS"
        fi

        printf "starting output...\n"

        if ! mysql "$USER" -p"$PWD" $SOCKET $HOST $PORT -e "SELECT * FROM $DB.$TB" >"$FILE"; then
            printf "[Err] 导出错误，退出\n" && exit 1
        fi

        printf "output is successfully finished, '%s' is created.\n" "$FILE"
    else
        # select2csv
        # count rows
        read -rp "Do you want to count table's rows(y/n):" answer

        if [ "$answer" = "y" ]; then
            COUNT=$(echo "$SQL" | sed -re 's/select.+from/select count(*) from/g')
            ROWS=$(mysql "$USER" -p"$PWD" $SOCKET $HOST $PORT -e "$COUNT" | grep -E "^[0-9]+")
            printf "Table的总行数: %s \n" "$ROWS"
        fi

        printf "starting output...\n"
        if ! mysql "$USER" -p"$PWD" $SOCKET $HOST $PORT -e "$SQL" >"$FILE"; then
           printf "[Err] 导出错误，退出\n" && exit 1
        fi
        printf "output is successfully finished, '%s' is created.\n" "$FILE"
    fi

}


function formatCsv() {
    printf "starting format the csv...\n"
    sed -i 's/\t/\,/g' "$1"
    printf "format is successfully finished.\n"
}

# main
while [ "$1" != "" ]; do

    if echo "$1" | grep -E "\-\w+" >/dev/null; then
        PARAM="$1"
        VALUE="$2"
        case "$PARAM" in
        --help)         help; exit 0 ;;
        -u|--user)      USER="-u$VALUE" ;;
        -S|--socket)    SOCKET="-S $VALUE" ;;
        -h|--host)      HOST="-h $VALUE" ;;
        -P|--port)      PORT="-P $VALUE" ;;
        -D|--databaes)  DB="$VALUE" ;;
        -T|--table)     TB="$VALUE" ;;
        -f|--file)      FILE="$VALUE" ;;
        --sql)          SQL="$VALUE" ;;
        esac
    else
        shift
        continue
    fi
    shift
done

ckPwd
dumpCsv
#formatCsv "$FILE"
exit 0