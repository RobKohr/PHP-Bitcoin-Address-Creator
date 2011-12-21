<?php
function bitcoin_address_pair(){
	$script =  dirname(__FILE__)."/botg.sh";
	exec($script, $result);
	$result = array_map('trim', $result);
	$priv = $result[2];
	$pub = $result[4];
	return array('private'=>$priv, 'public'=>$pub);
  }
