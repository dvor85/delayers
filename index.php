<?php
	echo '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">';
	//ini_set('display_errors',1);
	require_once("config/cf.php");	
	require_once("config/classes.php");	
	require_once("config/functions.php");
	echo "<html>";	
	echo "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=windows-1251\" >\r\n";	
	echo "<head>";
	echo "<style>";	
	echo "th {background-color:#cccccc;}";
	echo "table,fieldset {background-color:#eee;}";
	echo "td {font-size:14px;}";
	echo "</style>";
	echo "<script type='text/javascript' src='script.js'></script>";
	echo "</head>";
	echo "<body style='width:1024px;margin:auto'>";
	
	foreach ($_POST as $name => $value)
	{
		${$name}=substr(strip_tags(stripslashes(trim($value))),0,512);
		$_POST[$name]=substr(strip_tags(stripslashes(trim($value))),0,512);
	}
	
	
	
	$except_file="exceptions_".$_SERVER["PHP_AUTH_USER"];
	if (file_exists($except_file))
	    $exceptions=explode("\n",file_get_contents($except_file));
	else
	    $exceptions=array();
	
	$my=new datamysql(MYSQL_HOST,MYSQL_BASE,MYSQL_USER,MYSQL_PASS);
	//$my->debug=true;
	
	//$workers=&$my->query("select * from workers");
	
	
		
	//echo "<div style='text-align:center'>";

	
	/*if(isset($_POST["is_early"]))
	{	
		$is_delay=0;
		$is_early=1;
		$rep="Отчет по ранним уходам.";
	}	
	else
	{	
		$is_delay=1;
		$is_early=0;		
		$rep="Отчет по опоздавшим.";
	}*/	
		
	$rep="Отчет";	
	echo "<h1>$rep</h1>";
	
	
	echo "<fieldset>";
	echo "<legend>Фильтр</legend>";
	echo "<table>";
	echo "<form method='post' action=''>";
	
	echo "<tr><td align='left' width='270px'>От ";	
	echo "<script type=\"text/javascript\">";
	$d=(isset($dt1_year)&&isset($dt1_month)&&isset($dt1_day))?"var d=new Date($dt1_year,$dt1_month-1,$dt1_day,0,0,0,0);":"var d=new Date();";
	echo $d;
	echo "set_dateselect(d.getDate(),d.getMonth()+1,d.getFullYear(),'dt1');
		</script>";		
	echo "</td><td align='left' width='270px'>До ";	
	echo "<script type=\"text/javascript\">";
	$d=(isset($dt2_year)&&isset($dt2_month)&&isset($dt2_day))?"var d=new Date($dt2_year,$dt2_month-1,$dt2_day,0,0,0,0);":"var d=new Date();";
	echo $d;
	echo "set_dateselect(d.getDate(),d.getMonth()+1,d.getFullYear(),'dt2');
		</script>";	
	//echo "</td><td align='left' width='200px'>";
	
	/*echo "<select name='worker_id' style='width:100%'>";
	
	$worker_id=isset($_POST["worker_id"])?(int)substr(strip_tags(stripslashes(trim($_POST["worker_id"]))),0,16):"0";
		
	for ($i=0;$i<count($workers);$i++)
	{		
		$sworker=$workers[$i]["worker_name"];
		$sid_worker=$workers[$i]["id_worker"];
		if (in_array($sid_worker,$exceptions)) {
		    continue;
		}
		if ($worker_id==$sid_worker) 
			echo "<option value='$sid_worker' selected>$sworker</option>";
		else
			echo "<option value='$sid_worker'>$sworker</option>";
	}
	echo "</select>";*/
	//echo "</td>";		
	echo "<td align='right'><input type='submit' name='set_period' value='Применить'></td></tr>";
	echo "</form>";
	echo "</table>";
	echo "</fieldset>";
	echo "<br>";

	
	
if (isset($_POST["dt1_day"])&&isset($_POST["dt1_month"])&&isset($_POST["dt1_year"])&&isset($_POST["dt2_day"])&&isset($_POST["dt2_month"])&&isset($_POST["dt2_year"]))
{
	$dt1_day=(int)substr(strip_tags(stripslashes(trim($_POST["dt1_day"]))),0,2);    		
	$dt1_month=(int)substr(strip_tags(stripslashes(trim($_POST["dt1_month"]))),0,2);
	$dt1_year=(int)substr(strip_tags(stripslashes(trim($_POST["dt1_year"]))),0,4);
	$dt1="$dt1_year-$dt1_month-$dt1_day";
	
	$dt2_day=(int)substr(strip_tags(stripslashes(trim($_POST["dt2_day"]))),0,2);    		
	$dt2_month=(int)substr(strip_tags(stripslashes(trim($_POST["dt2_month"]))),0,2);
	$dt2_year=(int)substr(strip_tags(stripslashes(trim($_POST["dt2_year"]))),0,4);
	$dt2="$dt2_year-$dt2_month-$dt2_day";
	$minutes_per_day = 528;
	
	if (isset($_POST["set_period"])) {
	$q="select *  
		from events inner join workers on events.id_worker=workers.id_worker where (DATE(datetime_event) between '$dt1' and '$dt2') order by workers.id_worker,id_event";	
	//$q="select id_event,datetime_event,delay,workers.id_worker,worker_name,sum_delay,worker_ip,reason
	//	from events inner join 
	//	(workers inner join (select id_worker,sum(delay)as sum_delay from events where DATE(datetime_event) between '$dt1' and '$dt2' group by id_worker) as a on a.id_worker=workers.id_worker) 
	//	on events.id_worker=workers.id_worker where DATE(datetime_event) between '$dt1' and '$dt2' order by workers.id_worker;";
	//echo $q;
	$events=&$my->query($q);
	//$reasons=&$my->query("select * from predefined_reasons");
	//var_dump($events);
	
	if ($events) {
		$id_worker=$events[0]["id_worker"];
		$prev_id_worker=$events[0]["id_worker"];
		$worker_name=$events[0]["worker_name"];	
		$ip=$events[0]["ip"];
	}
	echo "<hr><h3><a href='#$id_worker|$ip' title='id=$id_worker'>$worker_name</a></h3><table border='1' width='100%' cellpadding='2px'>";
	echo "<tr><th width='20%'>Дата</th><th width='15%'>Опоздание, мин.</th><th width='25%'>Причина</th><th width='15%'>Ранний уход, мин.</th><th width='25%'>Причина</th></tr>";
	$sum_delay=0;	
	$sum_early=0;
	$count_wd=0;
	$count=0;
	//$sum_by_delay_reasons=array();
	//$sum_by_early_reasons=array();
	/*$q="SELECT 
				(sum(530-(IF(abs(delay)<530,delay,0)-IF(abs(events.early)<530,early,0)))/sum(530)) as effect  
			FROM events
			WHERE (DATE(datetime_event) BETWEEN '$dt1' and DATE(NOW())) AND (id_worker=$worker_id);";*/
	//$effect = &$my->query($q);
	for ($i=0;$i<count($events);$i++)
	{
		$id_worker=$events[$i]["id_worker"];
		if (in_array($id_worker,$exceptions)) {
		    continue;
		}
			
		$btime=mktime(9,0,0,date("n",strtotime($events[$i]["datetime_event"])),date("j",strtotime($events[$i]["datetime_event"])),date("Y",strtotime($events[$i]["datetime_event"])));
		$datetime_event=($id_worker=="600300058")?date("Y-m-d H:i:s",strtotime($events[$i]["datetime_event"])-$btime>1800?strtotime($events[$i]["datetime_event"])-1800:strtotime($events[$i]["datetime_event"])):$events[$i]["datetime_event"];
		//$datetime_event=$events[$i]["datetime_event"];
		$worker_name=$events[$i]["worker_name"];	
		$ip=$events[$i]["ip"];
		
		//$type_early_reason=$events[$i]["type_early_reason"];
		//$type_delay_reason=$events[$i]["type_delay_reason"];
		//$sdelay_reason=$reasons[$type_delay_reason]["reason"];
		//$searly_reason=$reasons[$type_early_reason]["reason"];
		
		//$delay_reason=$sdelay_reason.": ".$events[$i]["delay_reason"];
		//$early_reason=$searly_reason.": ".$events[$i]["early_reason"];
		$delay_reason=$events[$i]["delay_reason"];
		$early_reason=$events[$i]["early_reason"];
		
		$delay=$events[$i]["delay"];
		$early=-$events[$i]["early"];		
		$is_delay=$events[$i]["is_delay"];
		$is_early=$events[$i]["is_early"];
		//$effect=$events[$i]["effect"];
		//var_dump($is_early);
		$delay_color=($is_delay)?"#ff0000":"#00ff00";
		$early_color=($is_early)?"#ff0000":"#00ff00";
		//$delay_str=date("H:i:s",$delay);		
		if ($id_worker!=$prev_id_worker)
		{
			//$sum_delay_str=date("H:i:s",$sum_delay);
			$sum_delay_color=($sum_delay>0)?"#ff0000":"#00ff00";
			$sum_early_color=($sum_early>0)?"#ff0000":"#00ff00";

			$effect=($count_wd>0)?round(100*(($minutes_per_day*$count)-($sum_delay+$sum_early))/($minutes_per_day*$count_wd)):"&#8734";
			if ($effect<0) $effect=0;
			echo "<tr><th colspan='1' align='right'>Всего за $count дн:</th><th style='color:$sum_delay_color'>$sum_delay</th><th align='right'>Всего за $count дн:</th><th style='color:$sum_early_color'>$sum_early</th><th>Эффективность = $effect%</th></tr>";
			echo "</table><br><hr style='page-break-after:always'><h3><a href='#$id_worker|$ip' title='id=$id_worker'>$worker_name</a></h3>";
			echo "<table border='1' width='100%' cellpadding='2px'>";
			echo "<tr><th width='20%'>Дата</th><th width='15%'>Опоздание, мин.</th><th width='25%'>Причина</th><th width='15%'>Ранний уход, мин.</th><th width='25%'>Причина</th></tr>";
			/*for ($r=0;$r<count($reasons);$r++)
			{
				$sum_delay_color=($sum_by_delay_reasons[$r]>0)?"#ff0000":"#00ff00";
				$sum_early_color=($sum_by_early_reasons[$r]>0)?"#ff0000":"#00ff00";
				$dres=$reasons[$r]["reason"];
				echo "<tr><th colspan='2' align='right'>$dres за $count дн:</th><th style='color:$sum_delay_color'>$sum_by_delay_reasons[$r]</th>";
				echo "<th align='right'>$dres за $count дн:</th><th style='color:$sum_early_color'>$sum_by_early_reasons[$r]</th><th></th></tr>";
			}
			*/
			
			$prev_id_worker=$id_worker;
			$sum_delay=0;
			$sum_early=0;
			$count=0;
			$count_wd=0;
			//$sum_by_delay_reasons=array();
			//$sum_by_early_reasons=array();
		}
		$sum_delay+=abs($delay)<$minutes_per_day?$delay:0;	
		$sum_early+=abs($early)<$minutes_per_day?$early:0;
		//$sum_by_delay_reasons[$type_delay_reason]+=$delay;
		//$sum_by_early_reasons[$type_early_reason]+=$early;
		$count++;
		if ((int)date("N",strtotime($datetime_event))<6) {
			$count_wd++;
		}
		echo "<tr><td>$datetime_event</td><td style='color:$delay_color'>$delay</td><td>$delay_reason</td><td style='color:$early_color'>$early</td><td>$early_reason</td></tr>";
	}
	
	/*if ($events)
	{
		//$sum_delay_str=date("H:i:s",$sum_delay);
		$sum_delay_color=($sum_delay>0)?"#ff0000":"#00ff00";
		$sum_early_color=($sum_early>0)?"#ff0000":"#00ff00";		
		echo "<tr><th colspan='2' align='right'>Всего за $count дн</th><th style='color:$sum_delay_color'>$sum_delay</th><th align='right'>Всего за $count дн:</th><th style='color:$sum_early_color'>$sum_early</th><th></th></tr>";
		for ($r=0;$r<count($reasons);$r++)
		{
			$sum_delay_color=($sum_by_delay_reasons[$r]>0)?"#ff0000":"#00ff00";
			$sum_early_color=($sum_by_early_reasons[$r]>0)?"#ff0000":"#00ff00";
			$dres=$reasons[$r]["reason"];
			echo "<tr><th colspan='2' align='right'>$dres за $count дн:</th><th style='color:$sum_delay_color'>$sum_by_delay_reasons[$r]</th>";
			echo "<th align='right'>$dres за $count дн:</th><th style='color:$sum_early_color'>$sum_by_early_reasons[$r]</th><th></th></tr>";
		}
	}	*/
	$sum_delay_color=($sum_delay>0)?"#ff0000":"#00ff00";
	$sum_early_color=($sum_early>0)?"#ff0000":"#00ff00";
	
	$effect=($count_wd>0)?round(100*(($minutes_per_day*$count)-($sum_delay+$sum_early))/($minutes_per_day*$count_wd)):"&#8734";
	if ($effect<0) $effect=0;
	echo "<tr ><th colspan='1' align='right'>Всего за $count дн:</th><th style='color:$sum_delay_color'>$sum_delay</th><th align='right'>Всего за $count дн:</th><th style='color:$sum_early_color'>$sum_early</th><th>Эффективность = $effect%</th></tr>";
			
	/*$q="select workers.id_worker,workers.worker_name,
				sum(530-(IF((abs(events.delay)<530),events.delay,0)-
				IF((abs(events.early)<530),events.early,0))) as fact, 
				sum(530) as norma,
				(sum(530-(IF((abs(events.delay)<530),events.delay,0)-
				IF((abs(events.early)<530),events.early,0)))/sum(530)) as effect  
			from events right join workers on (events.id_worker=workers.id_worker) and (DATE(datetime_event) between '$dt1' and '$dt2') 
			where (workers.id_worker=$worker_id) 
			group by workers.worker_name,workers.id_worker;";
	if ($events) {
		$events=&$my->query($q);		
		//echo "<table border='1' width='100%' cellpadding='2px'>";
		//echo "<tr><th width='250px'>Имя</th><th width='150px'>Фактически, мин.</th><th width='150px'>Нужно, мин.</th><th>Эффективность</th></tr>";
		$id_worker=$events[0]["id_worker"];
		$worker_name=$events[0]["worker_name"];
		$fact=$events[0]["fact"];
		$norma=$events[0]["norma"];
		$effect=$events[0]["effect"];
		
		echo "<tr><th>Отработано, мин</th><th>$fact</th><th>Норма, мин.</th><th>$norma</th><th>Эффективность</th><th>$effect</th></tr>";
	}*/
	
	echo "</table><br><hr style='page-break-after:always'>";
	
	} elseif (isset($_POST["get_report"])) {
		
	}	
}

echo "</body></html>";
?>

