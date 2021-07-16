#!/bin/bash

sed -i "s/ZBX_WIN_LOCAL_PATH/C:\\Zabbix/gi" $1

ls=$(ls --hide=index.sh)

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
for a in ${ls}; do
page+="<a href='$a' download='$a' style='background-color: #f0f0f0; border: 1px solid #f4f4f4'>$a</a><br/>"
done


page+="""
</body>
</html>
"""
echo $page >index.php
