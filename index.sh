#!/usr/bin/env bash

files=$(ls --hide=index.sh)

replace(){
    sed -i "s/ZBX_WIN_LOCAL_PATH/C:\\Zabbix/gi" $1
    sed -i 's/ZBX_SERVER/http\:\/\/bmonit.beltis.com.br\:81\//gi' $1
}

folder_handler(){
    echo "path:$1"
    folderFiles=$(ls $1 --hide=Readme.md)
    for file in ${folderFiles}; do 
        echo "$1/$file"
        if [ -d $file ]; then
            folder_handler "$1/$file"
        else
            replace $file
            page+="<a href='$file' download='$file' style='margin-left:10px;background-color: #f0f0f0; border: 1px solid #f4f4f4'>$1/$file</a><br/>"
        fi
    done
}

page="""<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <meta http-equiv='X-UA-Compatible' content='IE=edge'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Zabbix Automation files</title>
</head>
<body>
"""

for file in ${files}; do     
 if [ -d $file ]; then
    path=$(pwd)
    folder_handler "$file"
 elif [ -f $file ]; then
    replace $file
    page+="<a href='$file' download='$file' style='background-color: #f0f0f0; border: 1px solid #f4f4f4'>$file</a><br/>"
 else
    replace $file
    page+="<a href='$file' download='$file' style='background-color: #f0f0f0; border: 1px solid #f4f4f4'>$file</a><br/>"
 fi
done

page+="""
</body>
</html>
"""
echo $page >index.php
