<?php

$length = \random_int(16, 256);
$characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
$charactersLength = strlen($characters);
$randomString = '';

for ($i = 0; $i < $length; $i++) {
    $randomString .= $characters[\random_int(0, $charactersLength - 1)];
}

echo $randomString.PHP_EOL;

exit(0);
