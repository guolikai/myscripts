#!/bin/bash
AppName=oracle
AppUser=cheuser
AppUserPw=cheuserpass
AppBackupDir=/opt/backup/oracle/sysload_file_dir

Today=$(date -d '0 days' +'%Y%m%d')
CURRENT_TIME=$(date -d '0 days' +'%Y%m%d%H%M%S')
SaveDays=6

fBackupExpdp(){
    # expdp cheplus/che91Plus dumpfile=PF_prod20190222.dmp directory=SYSLOAD_FILE_DIR logfile=SYSLOAD_FILE_DIR:PF_prod20190222.log
if [ $# -eq 0 ];then
    expdp ${AppUser}/${AppUserPw} dumpfile=PF_prod_${CURRENT_TIME}.dmp directory=SYSLOAD_FILE_DIR logfile=SYSLOAD_FILE_DIR:PF_prod_${CURRENT_TIME}.log &&  echo "备份成功,文件存储在${AppBackupDir}/PF_prod_${CURRENT_TIME}.dmp"
    find ${AppBackupDir} -name *${Today}*.dmp | xargs xz -z &
else
    echo "USAGE: $0 expdp"
    exit 1
fi
}


fBackupImpdp(){
#impdp  cheplus1/che91Plus remap_schema=cheplus:cheplus remap_tablespace=cheplus:cheplus directory=sysload_file_dir  dumpfile=PF_prod20190222.dmp table_exists_action=replace transform=OID:N

if [ $# -eq 0 ];then
    impdp ${AppUser}/${AppUserPw} remap_schema=cheplus:cheplus remap_tablespace=cheplus:cheplus directory=sysload_file_dir  dumpfile=PF_prod_${CURRENT_TIME}.dmp table_exists_action=replace transform=OID:N && echo "Oracl数据恢复成功"
else
    echo "USAGE: $0 impdp"
    exit 1
fi
}


ScriptDir=$(cd $(dirname $0); pwd)
ScriptFile=$(basename $0)

case "$1" in
    "expdp"  ) fBackupExpdp $2;;
    "impdp"  ) fBackupImpdp $2;;
     * )
    echo "${ScriptFile} expdp       备份数据 ${AppName}"
    echo "${ScriptFile} impdp       恢复数据 ${AppName}"
    ;;
esac
