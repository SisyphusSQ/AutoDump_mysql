# dump2csv.sh

这个脚本旨在自动校验mysql实例的参数和需要导出的数据数量后，导出数据。

校验的参数：
- GTID是否开启
在没有开启的情况下，不会加--set-gtid-purged=off

- binlog是否开启
在没有开启的情况下，不会加--master-data=2

## Usage
```bash
./dump2sql.sh [options] -s socket -u root -f file -D db -T table
```

## Options
```-u|--user``` Database user name

```-s|--socket``` Database socket

```-h|--host``` Database host

```-P|--port``` Database port

```-D|--databaes``` Database name

```-T|--table``` Database table name 

```-f|--file``` output file and its full path

```-g|--gzip``` gzip the output file

---

# dump2csv.sh

# dump2csv.sh

这个脚本旨在没有secure-file-priv权限的时候，用mysql -e导出数据，并处理为csv。

## Usage
```bash
./dump2csv.sh [options] -s socket -u root -f file -D db -T table
```

## Options
```-u|--user``` Database user name

```-s|--socket``` Database socket

```-h|--host``` Database host

```-P|--port``` Database port

```-D|--databaes``` Database name

```-T|--table``` Database table name 

```-f|--file``` output file and its full path