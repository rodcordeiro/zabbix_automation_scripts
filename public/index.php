<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
<?php
 if(isset($_GET['updates'])){
     $updates = json_encode(array(
        "windows"=>array(
            array(
                "id"=>000,
                "desc"=>"Criando script de atualização",
                "comandos"=>array("download file","create file","what else")
            ),
            array(
                "id"=>001,
                "desc"=>"Criando script de atualização",
                "comandos"=>array("download file","create file","what else")
            )
        ),
        "linux"=>array()
    ));
    echo $updates;
 } else {
?>
 <h1>Teste</h1>
<?php   
 };
?>
</body>
</html>