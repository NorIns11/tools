#!/bin/bash
# 确保在 git 仓库中
if [ ! -d ".git" ]; then
  exit "不是一个git仓库"
fi

# 获取当前分支名称
current_branch=$(git rev-parse --abbrev-ref HEAD)

# 检查当前分支是否与 origin/master 一致
if [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/master)" ]; then
  echo "当前分支与 origin/master 一致"
else
  echo "当前分支 '$current_branch' 与 origin/master 不一致"

  # 询问用户是否继续
  read -p "你想继续吗? (y/n): " answer

  # 检查用户输入
  case $answer in
    [Yy] ) echo -e "\033[44;37m 继续 \033[0m";;
    [Nn] ) echo -e "\033[44;37m 退出 \033[0m"; exit 1;;
    * ) echo "无效的输入"; exit 1;;
  esac
fi

# 项目名称
projectName="demo"
# 在服务器上的目录
filePath="/home/code/app/$projectName"
# 打包生成的文件夹名
buildDirName="dist"
user="root"
host=""
# 当前时间戳，服务器代码备份后缀
currentTime=$(date "+%Y%m%d%H")
# 是否需要在服务器上执行 npm install
needInstall=false
buildScript="build:stage"

if [ $1 == "dev" ]; then
    host="192.168.0.0"
elif [ $1 == "prod" ]; then
    host="192.168.0.0"
    buildScript="build:prod"
else
    exit "your params is not dev or prod"
fi

# 执行打包命令
npm run $buildScript
echo -e "\033[44;37m 项目打包成功 \033[0m"

# 压缩打包后的文件
zip -r build.zip ./$buildDirName/*

# 迁移压缩文件到服务器对应目录下
scp ./build.zip root@$host:$filePath
echo -e "\033[44;37m 资源文件迁移成功 \033[0m"

# 登陆到服务器，进行备份和解压操作，不要修改缩进
ssh $user@$host << eeooff
cd $filePath
zip -r build.zip.old ./$buildDirName/*
cp ./build.zip.old $filePath/backup/build.zip.old
unzip -o build.zip

cd $filePath/backup
mv build.zip.old build.zip.$currentTime

if [ $needInstall == true ]; then
    # nvm use 10.24.1
    npm install
fi

exit
eeooff
echo -e "\033[44;37m 服务器操作完成 \033[0m"

# 上传后删除本地的压缩文件
rm -rf build.zip
echo -e "\033[44;37m 发布成功！ \033[0m"
