#!/bin/bash
# Program:
#   dump2sql
#   使用mysqldump导出sql.gz文件
#
# v0.1 by alex.zhao 2021/03/18
#
# 语法:
#   ./dump2sql.sh socket user file database tb
#
# 例子：
#   ./dump2sql.sh /data/mysql/3322/mysql.sock root /tmp/test.sql.gz test file_push_log
####################################################

# mysql -S /data/mysql/3322/mysql.sock -uroot -proot

# 设置颜色
red='\e[0;31m' # 红色
NC='\e[0m'     # 没有颜色

# init
num=$#
socket=$1
user=$2
file=$3

# check
[ $num -lt 4 ] && printf "[Err] $red请检查参数$NC\n" && exit 1

# import password
read -s -rp "Enter Password:" pwd
printf "\n"

# check password
mysql -S "$socket" -u"$user" -p"$pwd" -e "select @@version;" >/dev/null
[ $? -ne 0 ] && printf "[Err] $red密码错误$NC\n" && exit 1

# dump database
function dumpDatabase() {
    # 检查是否存在这个库，然后停顿提醒要不要dump
    mysql -S "$socket" -u"$user" -p"$pwd" -e "SELECT * FROM information_schema.tables WHERE table_schema = '$2'" | grep "$2" >/dev/null
    [ $? -ne 0 ] && printf "[Err] $red DB不能存在请检查$NC\n" && exit 1

    read -rp "Do you want to dump this DB '$2'(y/n):" answer
    if [ "$answer" != "y" ]; then
        printf "Now exiting...\n"
        exit 0
    fi

    mysqldump -R -E --triggers --master-data=2 --single-transaction -u"$user" -p"$pwd" -S "$socket" -B "$2" | gzip >"$1"
    [ $? -ne 0 ] && printf "[Err] $red DB导出失败，请检查$NC\n" && exit 1

    printf "%s is created.\n" "$1"

    exit 0
}

# dump table
function dumpTable() {
    # 检查有没有这张表，检查行数，停顿提醒要不要dump
    mysql -S "$socket" -u"$user" -p"$pwd" -e "SELECT * FROM information_schema.tables WHERE table_schema = '$2' AND TABLE_NAME = '$3'" | grep "$3" >/dev/null
    [ $? -ne 0 ] && printf "[Err] $red Table不能存在请检查$NC\n" && exit 1

    # count rows
    read -rp "Do you want to count table $3 rows(y/n):" answer

    if [ "$answer" = "y" ]; then
        rows=$(mysql -S "$socket" -u"$user" -p"$pwd" -e "SELECT count(*) FROM $2.$3" | grep -E "^[0-9]+")

        printf "%s的总行数: %s \n" "$3" "$rows"

    fi

    read -rp "Do you want to dump this Table '$3'(y/n):" answer
    if [ "$answer" != "y" ]; then
        printf "Now exiting...\n"
        exit 0
    fi

    mysqldump -R -E --triggers --master-data=2 --single-transaction -u"$user" -p"$pwd" -S "$socket" "$2" "$3" | gzip >"$1"

    [ $? -ne 0 ] && printf "[Err] $red table导出失败，请检查$NC\n" && exit 1

    printf "%s is created.\n" "$1"

    exit 0
}

# main
case "${num}" in
4)
    db=$4
    dumpDatabase "$file" "$db"
    ;;
5)
    db=$4
    tb=$5
    dumpTable "$file" "$db" "$tb"
    ;;
esac
