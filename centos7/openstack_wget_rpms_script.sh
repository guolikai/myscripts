 #!/bin/bash
# ---------------------------------------------------------
# Filename:    openstack_wget_rpms_script.sh
# Revision:    1.0
# Date:        2017-12-8
# Author:      GuoLikai
# Email:       glk73748196@sina.com
# Description: 下载OpenStack在线版本RPM包脚本
# Notes: openstack-newton|openstack-ocata|openstack-pike      
# ---------------------------------------------------------

# -------------- Export Variable -------------
AppName=openstack
AppSrcBase=/App/src/OPS
AppScriptBase=/App/script/OPS

ScriptDir=$(cd $(dirname $0); pwd)
ScriptFile=$(basename $0)
# ----------------- Include ------------------
# ----------------- Funciton -----------------
# FunNo: 01
# FunDescript: Check Openstack Version

fCheckVersion(){
    wget -O /tmp/$1  http://mirror.centos.org/centos/7/cloud/x86_64/$1  &> /dev/null
    if [ $? == 0 ];then
        Version=$1
        rm -rf /tmp/$1
    else
        Version=openstack-pike
    fi
    echo ${Version}	
}


# FunNo: 02
# FunDescript: Check Src Dir
fCheckSrcDir(){
    local OpenstackVersion=$1
    AppSrcDir=${AppSrcBase}/${OpenstackVersion}
    if [[ ! -d ${AppSrcDir}/common ]];then
        mkdir -p ${AppSrcDir}/common
    fi
    echo ${AppSrcDir}
}

# FunNo: 03
# FunDescript: Check Script Dir
fCheckScriptDir(){
    local OpenstackVersion=$1
    AppScriptDir=${AppScriptBase}/${OpenstackVersion}
    if [[ ! -d ${AppScriptDir} ]];then
       mkdir -p ${AppScriptDir}
    fi
    echo ${AppScriptDir}
}


# FunNo: 04
# FunDescript: Analy Openstack rpm
fAnalyRpm(){
	if [[  $1 =~ "openstack" ]];then
        OpenstackVersion=`fCheckVersion $1`
	else
		echo "OpenStack版本参数有误,会默认下载openstack-pike版本"
        OpenstackVersion=openstack-pike
	fi

    AppSrcDir=`fCheckSrcDir ${OpenstackVersion}`
    AppScriptDir=`fCheckScriptDir ${OpenstackVersion}`
    echo "版本号:${OpenstackVersion} 下载路径:${AppSrcDir} 脚本路径:${AppScriptDir}"
    echo "http://mirror.centos.org/centos/7/cloud/x86_64/${OpenstackVersion}遍历rpm Starting"
    echo "#!/bin/bash"  >   ${AppScriptDir}/${OpenstackVersion}_wget_rpms_script.sh
    wget -O ${AppScriptDir}/${OpenstackVersion}.html          http://mirror.centos.org/centos/7/cloud/x86_64/${OpenstackVersion} &> /dev/null
    for RPM in `cat ${AppScriptDir}/${OpenstackVersion}.html | grep "href=" | awk -F"href="  '{print $2}' | awk -F"\""  '{print $2}'`
    do
        if [[ ${RPM} =~ "rpm" ]] &&  [[ ! -f ${AppSrcDir}/${RPM} ]];then
              echo "wget -O ${AppSrcDir}/${RPM}     http://mirror.centos.org/centos/7/cloud/x86_64/${OpenstackVersion}/${RPM}"	>>  ${AppScriptDir}/${OpenstackVersion}_wget_rpms_script.sh
        fi
    done
    echo "http://mirror.centos.org/centos/7/cloud/x86_64/${OpenstackVersion}/common遍历rpm Starting"
    wget -O ${AppScriptDir}/${OpenstackVersion}_common.html   http://mirror.centos.org/centos/7/cloud/x86_64/${OpenstackVersion}/common &> /dev/null
    for RPM in `cat ${AppScriptDir}/${OpenstackVersion}_common.html | grep "href=" | awk -F"href="  '{print $2}' | awk -F"\""  '{print $2}'`
    do
        if [[ ${RPM} =~ "rpm" ]] && [[ ! -f ${AppSrcDir}/common/${RPM} ]];then
              echo "wget -O ${AppSrcDir}/common/${RPM}     http://mirror.centos.org/centos/7/cloud/x86_64/${OpenstackVersion}/common/${RPM}"	>>  ${AppScriptDir}/${OpenstackVersion}_wget_rpms_script.sh
        fi
    done
      echo "${OpenstackVersion}版本RPM包Wget脚本收集完毕: ${AppScriptDir}/${OpenstackVersion}_wget_rpms_script.sh"
}

# FunNo: 05
# FunDescript: Download Openstack rpm
fDownLoad(){
   OpenstackVersion=`fCheckVersion $1`
   AppScriptDir=`fCheckScriptDir ${OpenstackVersion}`
   echo "版本号:${OpenstackVersion} 下载脚本路径:${AppScriptDir}"
   if [[  -f ${AppScriptDir}/${OpenstackVersion}_wget_rpms_script.sh ]];then
       #nohup /bin/bash  ${AppScriptDir}/${OpenstackVersion}_wget_rpms_script.sh &
       echo "${OpenstackVersion}后台RPM包下载中"
   else
       fAnalyRpm ${OpenstackVersion}
   fi
   nohup  /bin/bash  ${AppScriptDir}/${OpenstackVersion}_wget_rpms_script.sh  &
}


# ----------------- Main ---------------------
case "$1" in
    "analyrpm"    ) fAnalyRpm $2;;
    "download"    ) fDownLoad $2;;
      *           )
    echo "$ScriptFile analyrpm  [openstack-newton|openstack-ocata|openstack-pike]  分析脚本$AppName"
    echo "$ScriptFile download  [openstack-newton|openstack-ocata|openstack-pike]  下载RPM包$AppName"
;;
esac
