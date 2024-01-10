#!/bin/bash

echo "你需要一个已部署且可以访问的emby，并安装好docker。脚本开发：SMZDM:sonatasss 大佬。一键脚本by NetSE"
read -p "如果上述准备工作已做好，请回车开始本脚本；否则请 ctrl+c 退出脚本部署上述内容："

# 1. 创建目录
mkdir -p /mnt/user/appdata

# 2. 下载配置文件
wget https://gitee.com/sonata1/code-snippet/raw/master/%E6%9D%82%E4%B8%83%E6%9D%82%E5%85%AB/emby115/nginx-emby.tar.gz -O /mnt/user/appdata/nginx-emby.tar.gz

# 3. 解压配置文件
tar -xzvf /mnt/user/appdata/nginx-emby.tar.gz -C /mnt/user/appdata

# 4. 编辑脚本
read -p "请输入原Emby外网地址及端口（如：http://1.2.3.4:8096）：" new_emby_www && \
sed -i "s|emby_www = \"http://www.xxx.com:8096\"|emby_www = \"$new_emby_www\"|" /mnt/user/appdata/chronos-emby/scripts/emby115/emby115.py
read -p "请输入原emby内网地址及端口，可在emby后台查看，默认：http://172.17.0.1:8096（除非确有必要，请不要改IP），如不理解，请直接回车：" new_emby_loc && \
new_emby_loc=${new_emby_loc:-http://172.17.0.1:8096} && \
sed -i "s|emby_loc = \"http://172.17.0.1:8096\"|emby_loc = \"$new_emby_loc\"|" /mnt/user/appdata/chronos-emby/scripts/emby115/emby115.py
read -p "请输入115的cookie，推荐提取微信小程序的cookie；可直接复制alist挂载时填入的内容：" new_cookie && \
sed -i "s|cookie = 'cid;seid;uid'|cookie = '$new_cookie'|" /mnt/user/appdata/chronos-emby/scripts/emby115/emby115.py
read -p "请输入emby媒体库的本地路径，比如115网盘的/emby挂载，挂载到了/mnt/115，此处填入：/mnt/115 ：" new_local_path && \
sed -i "s|挂载字典={'/115本地路径':'/挂载的115远程路径',}|挂载字典={'$new_local_path':'/挂载的115远程路径',}|" /mnt/user/appdata/chronos-emby/scripts/emby115/emby115.py
read -p "请输入115网盘路径，比如115网盘的/emby挂载，挂载到了/mnt/115，此处填入：/emby挂载；如果挂载的是115根目录，直接回车确认：" new_remote_path && \
new_remote_path=${new_remote_path:-} && \
sed -i "s|'/挂载的115远程路径'|'$new_remote_path'|" /mnt/user/appdata/chronos-emby/scripts/emby115/emby115.py


# 5. 修改Emby工作端口
read -p "请输入Emby的原始地址，如果emby是本机安装，且未更改过端口，请直接回车；如果emby非本机安装，请输入（如：http://1.2.3.4:8096）：" emby_original_address
emby_original_address=${emby_original_address:-"http://172.17.0.1:8096"}
sed -i "s|http://172.17.0.1:8096|$emby_original_address|" /mnt/user/appdata/nginx-emby/conf.d/default.conf

# 6. 启用Nginx Docker容器
read -p "请输入新的Emby端口（回车默认为8097），就是你以后直链的emby端口，以后请访问新端口：" emby_docker_port
emby_docker_port=${emby_docker_port:-8097}
docker run --restart=always --name=nginx-emby --hostname=nginx-emby -p $emby_docker_port:80 --net=bridge -v /mnt/user/appdata/nginx-emby:/etc/nginx -v /tmp/dockernginx/cache:/tmp/dockernginx/cache -v /tmp/dockernginx/tmp:/tmp/dockernginx/tmp -d nginx

# 7. 启用转换直链的Python脚本Docker容器
docker run -itd -p 5001:5001 --name=chronos-emby --net=bridge --restart=always -v /mnt/user/appdata/chronos-emby:/chronos -e PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple simsemand/chronos

echo "部署已完成，请访问：$(curl -s ipinfo.io/ip):${emby_docker_port}。"
