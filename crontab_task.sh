* * * * * /bin/bash /home/quant_group/prometheus/pushgateway/icmp_gpu_monitor.sh 
0 0 * * * mysqldump -h172.27.1.12  -uroot -pOpsAny@2020 -A -B > /opt/guolikai/backup/opsany_`date -d '0 days' +'\%Y\%m\%d\%H\%M\%S'`.sql
0 10 * * * mysqldump -h172.27.1.10  -uopsae -pOpsAny@202Z autoops_qg > /opt/guolikai/backup/autoops_qg_`date -d '0 days' +'\%Y\%m\%d\%H\%M\%S'`.sql
10 0 * * * find /opt/guolikai/backup/ -ctime +2| grep -v mysql|xargs rm -rf ${i}

root@web2216-prd-tc5:/opt/guolikai/backup# cat /home/quant_group/prometheus/pushgateway/icmp_gpu_monitor.sh 
#!/bin/bash
#####################################
# Author: Guolikai
# Date：2022/04/07 17:30
# Description: Created by PyCharm
# prometheus使用pushgateway监控网路丢包 
# https://blog.csdn.net/qq_31555951/article/details/115136081
#####################################
#shell Env
#ping发包数
c_times=200
#IP列表数组
ip_arr=( 39.106.49.145 )

pushgateway_server=172.27.1.12
pushgateway_port=9091
for (( i = 0; i < ${#ip_arr[@]}; ++i ))
 do
         result=`timeout 16 ping -q -A -s 200 -W 250 -c $c_times   ${ip_arr[i]}|grep transmitted|awk '{print $6,$10}'`
         if [ -z "$result" ]
         then
               value_lostpk=101
               value_rrt=1000
               echo "ykt_lostpk_gt_jd ${value_lostpk}" | curl --data-binary @- http://${pushgateway_server}:${pushgateway_port}/metrics/job/ykt_icmp/instance/${ip_arr[i]}
               echo "ykt_rrt_gt_jd ${value_rrt}" | curl --data-binary @- http://${pushgateway_server}:${pushgateway_port}/metrics/job/ykt_icmp/instance/${ip_arr[i]}
         else
               lostpk=$(echo $result|awk '{print $1}')
               rrt=$(echo $result|awk '{print $2}')
               value_lostpk=$(echo $lostpk | sed 's/%//g')
               value_rrt=$(echo $rrt |sed 's/ms//g')
               #value_rrt=$(($value_rrt/$c_times))
               value_rrt=$(printf "%.5f" `echo "scale=5;$value_rrt/$c_times"|bc`)
               echo "ykt_lostpk_gt_jd ${value_lostpk}" | curl --data-binary @- http://${pushgateway_server}:${pushgateway_port}/metrics/job/ykt_icmp/instance/${ip_arr[i]}
               echo "ykt_rrt_gt_jd ${value_rrt}" | curl --data-binary @- http://${pushgateway_server}:${pushgateway_port}/metrics/job/ykt_icmp/instance/${ip_arr[i]}
         fi
         echo  ${ip_arr[i]}"==="$value_lostpk"==="$value_rrt
 done
