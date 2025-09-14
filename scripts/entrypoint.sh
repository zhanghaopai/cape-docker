#!/bin/bash

echo "Entrypoint started"
# 创建一些必要的文件夹
# 只有当/var/run/postgresql目录不存在时才创建
if [ ! -d "/var/run/postgresql" ]; then
    echo "Creating /var/run/postgresql directory"
    mkdir -p /var/run/postgresql
    chown -R postgres:postgres /var/run/postgresql
fi
# 只有当/work目录不存在时才创建
if [ ! -d "/work" ]; then
    echo "Creating /work directory"
    mkdir -p /work
fi

work=/work
if [ ! -d $work ]; then
    echo "Work directory not found"
    exit 1
else 
    sudo chown -R cape $work
fi

cwd="/opt/CAPEv2"
if [ ! -d $cwd ]; then
    echo "CAPEv2 not found"
    exit 1
fi 

if [ -L $cwd/conf ]; then
    echo "CAPEv2 configuration is a symbolic link"
elif [ -d $work/conf ]; then
    echo "CAPEv2 configuration backup found"
    rm -rf $cwd/conf
    chown -R cape $work/conf
    ln -s $work/conf $cwd/conf
elif [ -d $cwd/conf ]; then
    echo "CAPEv2 configuration found"
    mv $cwd/conf $work
    ln -s $work/conf $cwd/conf
fi

if [ -L $cwd/storage ]; then
    echo "CAPEv2 storage is a symbolic link"
elif [ -d $work/storage ]; then
    echo "CAPEv2 storage backup found"
    rm -rf $cwd/storage
    chown -R cape $work/storage
    ln -s $work/storage $cwd/storage
elif [ -d $cwd/storage ]; then
    echo "CAPEv2 storage found"
    mv $cwd/storage $work
    ln -s $work/storage $cwd/storage
else
    echo "CAPEv2 storage not found"
    sudo -u cape mkdir -p $work/storage
    ln -s $work/storage $cwd/storage
fi

if [ -L $cwd/log ]; then
    echo "CAPEv2 log is a symbolic link"
elif [ -d $work/log ]; then
    echo "CAPEv2 log backup found"
    rm -rf $cwd/log
    chown -R cape $work/log
    ln -s $work/log $cwd/log
elif [ -d $cwd/log ]; then
    echo "CAPEv2 log found"
    mv $cwd/log $work
    ln -s $work/log $cwd/log
else
    echo "CAPEv2 log not found"
    sudo -u cape mkdir -p $work/log
    ln -s $work/log $cwd/log
fi

echo "End of entrypoint"

# 启动supervisord来管理服务
echo "Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
