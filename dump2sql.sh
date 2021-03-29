#!/bin/bash
# Program:
#   dump2sql
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
GZIP=""
WHERE=""
GTID=""
MASTER=""
CON="-R -E --triggers --single-transaction"

# check password
function ckPwd () {
    # import password
    read -s -rp "Enter Password:" PWD
    printf "\n"

    echo "mysql $USER -p$PWD $SOCKET $HOST $PORT"
    if ! mysql "$USER" -p"$PWD" $SOCKET $HOST $PORT -e "select @@version;" >/dev/null; 
    then
        printf "[Err] 密码错误\n" && exit 1
    fi
    
    if mysql "$USER" -p"$PWD" $SOCKET $HOST $PORT -e "show variables like 'gtid_mode';"|grep "ON" >/dev/null; 
    then
        printf "[Info] GTID已开启\n"
        GTID="--set-gtid-purged=off"
    fi

    if mysql "$USER" -p"$PWD" $SOCKET $HOST $PORT -e "show variables like 'log_bin';"|grep "ON" >/dev/null; 
    then
        printf "[Info] binlog已开启\n"
        MASTER="--master-data=2"
    fi   
}

# Help Screen
function help() {
    echo -n "$0 [OPTIONS] -u UserName --host 192.168.0.1
Bash utility for dumping databases from remote host and localhost
GitHub Project:
  https://github.com/SisyphusSQ/autodump-mysql
Options:  
  -u|--user 	Database user name
  -s|--socket 	Database socket
  -h|--host 	Database host
  -P|--port 	Database port
  -D|--databaes Database name
  -T|--table 	Database table name
  -f|--file 	output file and its full path
  -g|--gzip 	gzip the output file
  -w|--where 	where condition
"
}

# dump
function dump () {

    if [ "$TB" != "" ]; then
        # 检查有没有这张表，检查行数，停顿提醒要不要dump
        if ! mysql "$USER" -p"$PWD" $SOCKET $HOST $PORT -e "SELECT * FROM information_schema.tables WHERE table_schema = '$DB' AND TABLE_NAME = '$TB'" | grep "$TB" >/dev/null; 
        then
            printf "[Err] Table不能存在请检查\n" && exit 1
        fi

         # count rows
         read -rp "Do you want to count table $TB rows(y/n):" answer

        if [ "$answer" = "y" ]; then
            rows=$(mysql "$USER" -p"$PWD" $SOCKET $HOST $PORT -e "SELECT count(*) FROM $DB.$TB" | grep -E "^[0-9]+")
            printf "%s的总行数: %s \n" "$TB" "$rows"
        fi

        read -rp "Do you want to dump this Table '$TB'(y/n):" answer
        if [ "$answer" != "y" ]; then
            printf "Now exiting...\n"
            exit 0
        fi       

        if ! mysqldump $USER -p$PWD $SOCKET $HOST $PORT $DB $TB $WHERE $CON $MASTER $GTID $GZIP > $FILE; then
            printf "[Err] Table导出失败，请检查\n" && exit 1
        fi
    else
        # 检查是否存在这个库，然后停顿提醒要不要dump
        if ! mysql "$USER" -p"$PWD" $SOCKET $HOST $PORT -e "SELECT * FROM information_schema.tables WHERE table_schema = '$DB'" | grep "$DB" >/dev/null; 
        then
            printf "[Err] DB不能存在请检查\n" && exit 1
        fi
        
        read -rp "Do you want to dump this DB '$DB'(y/n):" answer
        if [ "$answer" != "y" ]; then
            printf "Now exiting...\n"
            exit 0
        fi

        echo "mysqldump $USER -p$PWD $SOCKET $HOST $PORT -B $DB $TB $CON $MASTER $GTID $GZIP > $FILE"
        if ! mysqldump $USER -p$PWD $SOCKET $HOST $PORT -B $DB $TB $CON $MASTER $GTID $GZIP > $FILE; then
            printf "[Err] Database导出失败，请检查\n" && exit 1
        fi
    fi    
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
        -w|--where)     WHERE="-w $VALUE" ;;
        -g|--gzip)      GZIP="|gzip" ;;
        esac
    else
        shift
        continue
    fi
    shift
done

ckPwd
dump