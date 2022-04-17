#!/bin/sh
# 二进制安装管理mysql5.7.21
App=mysql-5.7.21-linux-glibc2.12-x86_64
AppName=mysql
AppInstallBase=/opt
AppInstallDir=${AppInstallBase}/${AppName}

AppSrcBase=${AppInstallBase}/soft
AppTarBall=${App}.tar.gz
AppBuildBase=${AppSrcBase}/build
AppBuildDir=$(echo "${AppBuildBase}/${AppTarBall}" | sed -e 's/.tar.*$//' -e 's/^.\///')
AppDataDir=${AppInstallBase}/data/${AppName}
AppLogDir=${AppInstallBase}/data/logs
AppConfDir=${AppInstallDir}/conf
AppMysqldProg=${AppInstallDir}/bin/mysqld
AppDaemonProg=${AppInstallDir}/bin/mysqld_safe
AppAdminProg=${AppInstallDir}/bin/mysqladmin
AppCnf=${AppConfDir}/my.cnf

IP=`ifconfig ens33 | grep inet | grep -v net6 |awk -F' ' '{print $2}'`
ip2=$(echo $IP | awk -F'.' '{print $2}')
ip3=$(printf "%03d\n" $(echo $IP | awk -F'.' '{print $3}'))
ip4=$(printf "%03d\n" $(echo $IP | awk -F'.' '{print $4}'))

ServerId=$(echo  ${ip2}${ip3}${ip4})
AppUid=10002
AppUser=mysql
AppGroup=mysql

RemoveFlag=0
InstallFlag=0

# 获取PID
fpid()
{
#    AppMasterPid=$(ps aux | grep "${AppDaemonProg}" | grep -v "grep" | awk '{print $2}' 2> /dev/null)
     AppMasterPid=$(ps aux | grep "mysqld" | grep -Ev "grep|mysqld_safe" | awk '{print $2}' 2> /dev/null)
}

# 查询状态
fstatus()
{
    fpid

    if [ ! -f "${AppAdminProg}" ]; then
            echo "${AppName} 未安装"
    else
        echo "${AppName} 已安装"
        if [ ! -d "${AppDataDir}" ]; then
            echo "${AppName} 未创建授权表"
        else
            if [ -z "${AppMasterPid}" ]; then
                echo "${AppName} 未启动"
            else
                echo "${AppName} 正在运行"
            fi
        fi
    fi
}

# 删除
fremove()
{
    fpid    
    RemoveFlag=1

    if [ -z "${AppMasterPid}" ]; then
        if [ -d "${AppInstallDir}" ]; then
            rm -rf ${AppInstallDir} && echo "删除 ${AppName}"
            [ ! -d ${AppInstallDir} ]  && echo "删除 ${AppName}"
        else
            echo "${AppName} 未安装"
        fi
    else
        echo "${AppName} 正在运行" && exit 1
    fi
}

# 备份
fbackup()
{
    Day=$(date +%Y-%m-%d)
    BackupFile=${AppName}-${Day}.tgz

    if [ -f "${AppDaemonProg}" ]; then
        cd ${AppInstallBase}
        tar zcvf ${BackupFile} --exclude=data/* --exclude=var/* ${AppName}/* --backup=numbered
        [ $? -eq 0 ] && echo "${AppName} 备份成功" || echo "${AppName} 备份失败"
    else
        echo "${AppName} 未安装"
    fi
}

# 安装依赖
finsdep()
{
#    yum install gcc gcc-c++ ncurses-devel zlib-devel cmake  numactl -y
    yum install numactl -y
}

# 安装
finstall()
{
    fpid
    InstallFlag=1
    
    if [ -z "${AppMasterPid}" ]; then
        test -f "${AppAdminProg}" && echo "${AppName} 已安装"
        [ $? -ne 0 ] && finsdep && fuser && fupdate
    else
        echo "${AppName} 正在运行"
    fi
}


# 更新
fupdate()
{
    Operate="更新"
    [ $InstallFlag -eq 1 ] && Operate="安装"
    [ $RemoveFlag -ne 1 ] && fbackup
	test -d "${AppBuildBase}" || mkdir -p ${AppBuildBase}
    test -d "${AppBuildDir}" && rm -rf ${AppBuildDir}
    tar zxf ${AppSrcBase}/${AppTarBall} -C ${AppBuildBase} || tar jxf ${AppSrcBase}/${AppTarBall} -C ${AppBuildBase}
    mv ${AppBuildDir}  ${AppInstallDir}

    if [ $? -eq 0 ]; then
        echo "${AppName} ${Operate}成功"
        [ ! -d ${AppConfDir} ] && mkdir -p ${AppConfDir}
        [ ! -d ${AppLogDir} ]  && mkdir -p ${AppLogDir}/{bin-log,error-log,relay-log,slow-log} && touch ${AppLogDir}/error-log/error.log
        cp -vf --backup=numbered ${ScriptDir}/mysql-5.7.21.init  /etc/init.d/mysql-5.7.21.init
        chmod u+x /etc/init.d/mysql-5.7.21.init
        cp -vf --backup=numbered ${ScriptDir}/mysql-5.7.21.cnf    ${AppConfDir}/my.cnf
        sed -i "s#report-host = 127.0.0.1#report-host = ${IP}#g"  ${AppConfDir}/my.cnf
        sed -i "/^server-id/cserver-id = ${ServerId}"             ${AppConfDir}/my.cnf
        cp -vf --backup=numbered ${AppConfDir}/my.cnf  /etc/my.cnf
        chown -R ${AppUser}.${AppUser} ${AppLogDir}
        chown -R ${AppUser}.${AppUser} ${AppInstallDir}
    else
        echo "${AppName} ${Operate}失败"
        exit 1
    fi
}

# 新建运行用户
fuser()
{
    id -gn ${AppGroup} &> /dev/null
    if [ $? -ne 0 ]; then
        groupadd ${AppGroup} && echo "新建 ${AppName} 运行组：${AppGroup}"
    else
        echo "${AppName} 运行组：${AppGroup} 已存在"
    fi

    id -un ${AppUser} &> /dev/null
    if [ $? -ne 0 ]; then
        useradd -s /bin/false -M  -u ${AppUid} -g ${AppGroup} ${AppUser} 
        if [ $? -eq 0 ]; then
            echo "新建 ${AppName} 运行用户：${AppUser}"
        fi
    else
        echo "${AppName} 运行用户：${AppUser} 已存在"
    fi
}

# 初始化授权表
finit()
{

    if [ ! -e "${AppDataDir}" ]; then
        mkdir -p ${AppDataDir} && echo "新建 ${AppName} 数据存储目录：${AppDataDir}"
        chown -R ${AppUser}.${AppUser} ${AppDataDir}
    elif [ ! -d "${AppDataDir}" ]; then
        echo "路径：${AppDataDir} 非目录"
    else
        echo "${AppName} 数据存储目录：${AppDataDir} 已存在"
    fi
        grep -q "MYSQL_HOME" /etc/profile || cat >> /etc/profile << EOF
########################################
export MYSQL_HOME=${AppInstallDir}
export PATH=\$MYSQL_HOME/bin:\$PATH
EOF
    #/opt/mysql/bin/mysqld --initialize  --basedir=/opt/mysql --datadir=/opt/data/mysql --user=mysql 
    #${AppMysqldProg}  --initialize --basedir=${AppInstallDir} --datadir=${AppDataDir} --user=${AppUser}
    echo "${AppMysqldProg}  --initialize --basedir=${AppInstallDir} --datadir=${AppDataDir} --user=${AppUser}" | /bin/bash
    [ $? -eq 0 ] && echo "成功 ${AppName} 授权表" && echo "注意在安装过程里有:MySQL Root初始密码"  || echo "${AppName} 授权表失败"
    [ -d ${AppInstallDir} ] && [ -d ${AppConfDir} ] && [ -d ${AppLogDir} ] && echo "${AppName} 已初始化"
}

# 启动
fstart()
{
    #/opt/mysql/bin/mysqld_safe --defaults-file=/opt/mysql/conf/my.cnf --datadir=/opt/data/mysql
    /bin/bash /etc/init.d/mysql start
    if [ $? = 0 ];then
        echo "${AppName} 启动成功"
    else
        echo "${AppName} 启动失败"
    fi
} 

# 停止
fstop()
{
    #mysqladmin -uroot -p123456 -S /tmp/mysql.sock shutdown
    /bin/bash /etc/init.d/mysql stop
    if [ $? = 0 ];then
        echo "${AppName} 成功关闭"
    else
        echo "${AppName} 关闭失败"
    fi
}


# 重启
frestart()
{
    fstop && sleep 1
    fstart 
}


ScriptDir=$(dirname $0)
ScriptFile=$(basename $0)

case "$1" in
    "install"   ) finstall;;
    "update"    ) fupdate;;
    "reinstall" ) fremove && finstall;;
    "remove"    ) fremove;;
    "backup"    ) fbackup;;
    "user"      ) fuser;;
    "init"      ) finit $@;;
    "start"     ) fstart $@;;
    "stop"      ) fstop $@;;
    "restart"   ) frestart $@;;
    "status"    ) fstatus;;
    "kill"      ) fkill $@;;
    *           )
    echo "${ScriptFile} install              安装 ${AppName}"
    echo "${ScriptFile} update               更新 ${AppName}"
    echo "${ScriptFile} reinstall            重装 ${AppName}"
    echo "${ScriptFile} remove               删除 ${AppName}"
    echo "${ScriptFile} backup               备份 ${AppName}"
    echo "${ScriptFile} init                 初始化 ${AppName}"
    echo "${ScriptFile} start                启动 ${AppName}"
    echo "${ScriptFile} stop                 停止 ${AppName}"
    echo "${ScriptFile} restart              重启 ${AppName}"
    echo "${ScriptFile} status               查询 ${AppName} 状态"
    echo "${ScriptFile} user                 新建 ${AppName} 运行用户"
    ;;
esac
