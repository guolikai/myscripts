#!/bin/bash
ScriptDir=$(cd $(dirname $0); pwd)
ScriptFile=$(basename $0)
ScriptFileLog=$(echo ${ScriptDir}|sed "s#/#_#g")

#AppDir=/opt/tomcat/webapps/ROOT
AppDir=/opt/tomcat/webapps
Ctime=$(date +'%Y%m%d%H%M%S')

for item in $(find ${ScriptDir} -type f | grep -v ${ScriptFile})
	do
		if [[ ${item} =~ classes ]];then
		    #new=$(echo ${item}|sed   "s#${ScriptDir}#${AppDir}/WEB-INF#")
		    new=$(echo ${item}|sed   "s#${ScriptDir}#${AppDir}#")
	    elif [[ ${item} =~ modules ]];then
		    new=$(echo ${item}|sed   "s#${ScriptDir}#${AppDir}#")
		else
		    new=$(echo ${item}|sed   "s#${ScriptDir}#${AppDir}#")
		fi
		
		#echo ${new}
		if [[ -f ${new}  ]];then
		   echo "文件存在 ${new}"
		   mv ${new} ${new}.bak${Ctime}
		   /usr/bin/cp -rf ${item} ${new}
		   echo "文件已替换 ${item}"
		else
           mkdir -p ${new%/*}
		   log_file= $(echo| sed 's#/#_#g')
		   #echo "文件不存在 ${new}"
		   echo "文件不存在 ${new}" >> ../${ScriptFileLog}_${Ctime}.log 
		   /usr/bin/cp -rf ${item} ${new}
		   echo "文件已复制 ${item}"
		fi
	done
echo "-----------------------------------------------------------------"
find  ${AppDir} -name "*${Ctime}*" >> ../${ScriptFileLog}_${Ctime}.log
UpdateNew=$(find ${ScriptDir} -type f | grep -v ${ScriptFile} | wc -l)
UpdatePre=$(find  ${AppDir} -name "*${Ctime}*" | wc -l)
echo "更新旧文件数:${UpdatePre} 新文件数:${UpdateNew}"
echo "更新旧文件数:${UpdatePre} 新文件数:${UpdateNew}" >> ../${ScriptFileLog}_${Ctime}.log
echo "-----------------------------------------------------------------"
