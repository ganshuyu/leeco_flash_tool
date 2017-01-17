#!/usr/bin/php
<?php
$debug = 1;
if (empty($argv[1]) || empty($argv[2])) {
    echo "Error argv!\n";
    exit();
}

#username and password
$name = base64_encode($argv[1]);
$password = base64_encode($argv[2]);

#str
if (empty($argv[3])) {
  $str=base64_encode("123456");
} else {
  $str=base64_encode($argv[3]);
}

$url = "https://secservice.letv.cn:444/LeEco/sign/index.php?user=$name&password=$password&string=$str";
$ret = file_get_contents($url);
$array = json_decode($ret);

$ret_status = $array->status;
echo "ret=$ret_status\n";

if ($ret_status == 0) {
    $encrypt_str = urldecode($array->result);
    echo_encrypt_data($encrypt_str);
}

function echo_encrypt_data($encrypt_str)
{
    $len = strlen($encrypt_str);
    for ($i=0; $i<$len; $i+=40) {
        $tmp = substr($encrypt_str, $i, 40);
        echo $tmp;
        echo "\n";
    }
}
