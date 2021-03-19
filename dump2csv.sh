#!/bin/bash
# Program:
#   dump2csv
#   使用mysqldump导出sql.gz文件
#
# v0.1 by alex.zhao 2021/03/18
#
# 语法:
#   ./dump2csv.sh socket user file database tb
#   ./dump2csv.sh socket user file select
#
# 例子：
#   ./dump2csv.sh /data/mysql/3322/mysql.sock root /tmp/test.csv test file_push_log
#   ./dump2csv.sh /data/mysql/3322/mysql.sock root /tmp/test.csv "select id,title from test.guider_group;"
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

function select2csv() {
    # count rows
    read -rp "Do you want to count table's rows(y/n):" answer

    if [ "$answer" = "y" ]; then
        count=$(echo "$1" | sed -re 's/select.+from/select count(*) from/g')

        rows=$(mysql -S "$socket" -u"$user" -p"$pwd" -e "$count" | grep -E "^[0-9]+")

        printf "Table的总行数: %s \n" "$rows"

    fi

    printf "starting output...\n"
    mysql -S "$socket" -u"$user" -p"$pwd" -e "$1" >"$file"

    [ $? -ne 0 ] && printf "[Err] $red导出错误，退出$NC\n" && exit 1
    printf "output is successfully finished, '%s' is created.\n" "$file"
}

function table2csv() {
    # count rows
    read -rp "Do you want to count table $3 rows(y/n):" answer

    if [ "$answer" = "y" ]; then
        rows=$(mysql -S "$socket" -u"$user" -p"$pwd" -e "SELECT count(*) FROM $db.$tb" | grep -E "^[0-9]+")

        printf "%s的总行数: %s \n" "$tb" "$rows"

    fi

    printf "starting output...\n"
    #mysql -S "$socket" -u"$user" -p"$pwd" -e "select * from $db.$tb" >"$file"

    [ $? -ne 0 ] && printf "[Err] $red导出错误，退出$NC\n" && exit 1
    printf "output is successfully finished, '%s' is created.\n" "$file"
}

function formatCsv() {
    printf "starting format the csv...\n"
    sed -i 's/\t/\,/g' "$1"
    printf "format is successfully finished.\n"
}

# main
if echo "$4" | grep " " >/dev/null; then
    select=$4
    select2csv "$select"

else
    db=$4
    tb=$5
    table2csv "$db" "$tb"
fi

formatCsv "$file"

exit 0