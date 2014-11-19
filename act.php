<?php
	ini_set('display_errors',0);
	require_once("config/cf.php");	
	require_once("config/classes.php");	
	require_once("config/functions.php");

	header('Content-type:text/html; charset=windows-1251');
	
	$my=new datamysql(MYSQL_HOST,MYSQL_BASE,MYSQL_USER,MYSQL_PASS);	
	$ip=getremoteaddr();
	
	
	
	if (isset($_POST["is_delay"]) && isset($_POST["delay"]) && !empty($_POST["id"]))
	{
		$is_delay=(int)substr(strip_tags(stripslashes(trim($_POST["is_delay"]))),0,9);
		$worker_name=substr(strip_tags(stripslashes(trim($_POST["name"]))),0,255);
		$id_worker=(int)substr(strip_tags(stripslashes(trim($_POST["id"]))),0,16);
		$reason=substr(strip_tags(stripslashes(trim($_POST["reason"]))),0,512);
		$type_reason=isset($_POST["type_reason"])?(int)substr(strip_tags(stripslashes(trim($_POST["type_reason"]))),0,16):'-1';
		$delay=(int)substr(strip_tags(stripslashes(trim($_POST["delay"]))),0,9);
		$workers=$my->query("select * from workers where id_worker=$id_worker limit 1");
		if (!$workers)
		{
			$my->uquery("insert into workers values($id_worker,'$worker_name')");
		}
		else
		{			
			//$worker_name_=$workers[0]["worker_name"];
			if ($worker_name<>'')
				$my->uquery("update workers set worker_name='$worker_name' where id_worker=$id_worker");
		}		
		//$sql="select * from events_delay where (id_worker=$id_worker) & (DATEDIFF(NOW(),datetime_event)=0)";
		//$today_events=&$my->query($sql);
		//if (!$today_events)
		//{
			//$my->debug=true;
			$my->uquery("insert into events (ip,id_worker,delay,delay_reason,type_delay_reason,is_delay,is_early) values('$ip',$id_worker,$delay,'$reason',$type_reason,$is_delay,1)");
		//}
	}	
	if (isset($_POST["is_early"]) && isset($_POST["early"]) && !empty($_POST["id"]))
	{
		$is_early=(int)substr(strip_tags(stripslashes(trim($_POST["is_early"]))),0,9);
		$worker_name=substr(strip_tags(stripslashes(trim($_POST["name"]))),0,255);
		$id_worker=(int)substr(strip_tags(stripslashes(trim($_POST["id"]))),0,16);
		$reason=substr(strip_tags(stripslashes(trim($_POST["reason"]))),0,512);
		$type_reason=isset($_POST["type_reason"])?(int)substr(strip_tags(stripslashes(trim($_POST["type_reason"]))),0,16):'-1';
		$early=(int)substr(strip_tags(stripslashes(trim($_POST["early"]))),0,9);
		$workers=$my->query("select * from workers where id_worker=$id_worker limit 1");
		if (!$workers)
		{
			$my->uquery("insert into workers values($id_worker,'$worker_name')");
		}
		else
		{	
			if ($worker_name<>'')
				$my->uquery("update workers set worker_name='$worker_name' where id_worker=$id_worker");
		}		
		$sql="select *,DATEDIFF(NOW(),datetime_event) as days_between from events where (id_worker=$id_worker) order by id_event desc limit 1";
		$events=&$my->query($sql);
		if (!$events)
		{
			//if ($is_early==1) //если записей нет, но есть опоздание или перезагрузка, то фиксируем. а вот если не ранний уход, то ничего не меняется
			$my->uquery("insert into events (ip,id_worker,early,early_reason,type_early_reason,is_early) values('$ip',$id_worker,$early,'$reason',$type_reason,$is_early)");				
		}
		else
		{
			$days_between=(int)$events[0]["days_between"];
			$id_event=(int)$events[0]["id_event"];
			$is_early_db=(int)$events[0]["is_early"];
			//var_dump($is_early_db);
			if (($days_between>0)&&($is_early_db==1)&&($reason!='')) //Причину пишем только на следующий день в предыдущую запись (по логике она должна существовать)
				$my->uquery("update events set early_reason='$reason',type_early_reason=$type_reason where (id_event=$id_event)");
			elseif (($days_between>0)&&($is_early_db==1)&&($reason=='')) // если не сегодня, но некорректное завершение - обновить запись (запись из буфера)
				$my->uquery("update events set is_early=$is_early,early=$early where (id_event=$id_event)");
			elseif ($days_between==0) // если день тот же, но ранний уход (например перезагрузка) - обновить запись
				$my->uquery("update events set ip='$ip',early=$early,is_early=$is_early where (id_event=$id_event)");
			elseif ($days_between>0) //если новый день, но ранний уход - добавить запись
				$my->uquery("insert into events (ip,id_worker,early,is_early) values('$ip',$id_worker,$early,$is_early)");
		}
	}
	
	
	if (isset($_POST["get_basedata"]) && !empty($_POST["id"]))
	{
		$id_worker=(int)substr(strip_tags(stripslashes(trim($_POST["id"]))),0,16);
		$events=&$my->query("select worker_name,early_reason,type_early_reason,early,is_early,is_delay,DATEDIFF(NOW(),datetime_event) as diffdays from events inner join workers on events.id_worker=workers.id_worker where (events.id_worker='$id_worker') order by id_event desc limit 1");		
		//print_r($events);
		$is_early=$events?$events[0]["is_early"]:0;	
		$is_delay=$events?$events[0]["is_delay"]:0;	
		$diffdays=$events?$events[0]["diffdays"]:0;
		$early=$events?$events[0]["early"]:0;
		$worker_name=($events)?$events[0]["worker_name"]:"Новый работник с компьютера $ip";
		$early_reason=$events?trim($events[0]["early_reason"]):'';
		$type_early_reason=$events?(int)trim($events[0]["type_early_reason"]):-1;
		$is_reg_early=(int)!(($is_early == 1) && ($diffdays > 0) && ($type_early_reason == -1));
		$is_reg_delay=(int)((!$events)xor($diffdays==0));
		$dt1=date("Y-m-d",mktime(0,0,0,date("n"),1,date("Y")));
		$q="SELECT 
				(sum(530-(IF(abs(delay)<530,delay,0)-IF(abs(events.early)<530,early,0)))) as worked,
                (IF(WEEKDAY(datetime_event)<5,sum(530),0)) as need_worked  
			FROM events
			WHERE (DATE(datetime_event) BETWEEN '$dt1' and DATE(NOW())) AND (id_worker=$id_worker)";
		/*$q="SELECT 
				(sum(530-(IF(abs(delay)<530,delay,0)-IF(abs(events.early)<530,early,0)))/sum(530)) as effect  
			FROM events
			WHERE (DATE(datetime_event) BETWEEN '$dt1' and DATE(NOW())) AND (id_worker=$id_worker);";*/
		$events=&$my->query($q);
		if ($events) {
			$worked=$events[0]["worked"];
			$need_worked=$events[0]["need_worked"];			
			if ($worked<0) {
				$effect=0;
			} else {
				$effect=($need_worked>0)?round($worked*100/$need_worked):-1;
			}
		} else {
			$effect=0;
		}
		
		//$effect=round($events?$events[0]["effect"]*100:100);
		echo "is_early=$is_early\n";
		echo "early_days=$diffdays\n";
		echo "early=$early\n";		
		echo "is_reg_early=$is_reg_early\n";
		echo "is_delay=$is_delay\n";
		echo "is_reg_delay=$is_reg_delay\n";
		echo "name=$worker_name\n";
		echo "effect=$effect";
	}
	
	if (isset($_POST["get_predefinedreasons"]))
	{
		$reasons=&$my->query("select * from predefined_reasons");
		for ($i=0;$i<count($reasons);$i++)
		{
			$reason=$reasons[$i]["reason"];
			echo "$reason\r\n";
		}
	}
?>

