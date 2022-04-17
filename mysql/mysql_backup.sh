#!/bin/bash
#AppBackupDir='/data/mysql_backup'
AppBackupDir='/data/backup/mysql/172.20.10.201'
Today=$(date -d '0 days' +'%Y%m%d')
Yesterday=$(date -d '-1 days' +'%Y%m%d')
SaveDays=2
#crontab -l
#01  01 * * *  mysqldump -ubackup -p'backup@123' -S /var/lib/mysql/mysql.sock  -A -B --master-data=1 --single-transaction >  /data/backup/mysql/mysql_all_databases_`date -d '0 days' +'\%Y\%m\%d-\%H\%M\%S'`.sql
[ -d ${AppBackupDir} ] || mkdir -p  ${AppBackupDir}
#find ${AppBackupDir}  -name "*.sql.xz" -type f -ctime +${SaveDays} -exec rm -f {} \;
find ${AppBackupDir}  -name "*.sql.*" -type f -atime +${SaveDays} | xargs  rm -f;
#mysqldump -ubackup -p'backup@123' -S /var/lib/mysql/mysql.sock  -A -B --master-data=1 --single-transaction >  ${AppBackupDir}/mysql_all_databases_`date -d '0 days' +'%Y%m%d-%H%M%S'`.sql && find ${AppBackupDir} -name mysql_all_databases_${Yesterday}* | grep -v xz  | xargs xz -z &
mysqldump -ubackup -p'backup@123' -S /var/lib/mysql/mysql.sock  -A -B --master-data=1 --single-transaction >  ${AppBackupDir}/mysql_all_databases_`date -d '0 days' +'%Y%m%d-%H%M%S'`.sql && find ${AppBackupDir} -name mysql_all_databases_${Today}* | grep -v xz  | xargs xz -z &
chown -R :newnew /data/backup
