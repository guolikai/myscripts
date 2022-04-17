#!/bin/bash
#变量定义  
ip_array=("172.16.1.11" "127.0.0.1")  
user="root"
password="20i9@123"
remote_cmd="ip a | grep global | grep -v 'docker'|awk -F ' |/' '{print \$6}'"
save_file="port_minoter.log"
port_array=("22" "8080" "9090")

fportmonitor ()
{
if [ -f "${save_file}" ]; then
    rm -rf ${save_file}
fi
#本地通过ssh执行远程服务器的脚本  
for ip in ${ip_array[*]}  
do  
    if [ $ip = "192.168.1.1" ]; then  
        port="7777"  
    else  
        port="22"  
    fi  
        result=$(/usr/bin/ssh  $user@$ip "$remote_cmd")
 -        for port in ${port_array[*]}
        do
            
            res_port=$(/usr/bin/ssh  $user@$ip "/usr/bin/netstat -lnutp | grep -w '${port}' | wc -l")
            #echo 'ip':${ip},'port':${result}:${port},${res_port}
            echo "{'ip':${result},'port':${port},'count':${res_port}}" >> ${save_file}
	done
done
}

fportmonitor
