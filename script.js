function set_dateselect(day,month,year,name)
{
	var months = ['Январь','Февраль','Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];	
	document.writeln('<select class=\"formbut\" name=\"'+name+'_day\">');
	for (d=1;d<=31;d++)
	{
		if (day==d)
			document.writeln('<option value='+d+' selected>'+d+'</option>');
		else
			document.writeln('<option value='+d+'>'+d+'</option>');	
	}				
	document.writeln('</select>');
	document.writeln('<select class=\"formbut\" name=\"'+name+'_month\">');
	for (m=1;m<=12;m++)
	{	
		if (month==m)
			document.writeln('<option value='+m+' selected>'+months[m-1]+'</option>');
		else
			document.writeln('<option value='+m+'>'+months[m-1]+'</option>');
	}		
	document.writeln('</select>');
	document.writeln('<select class=\"formbut\" name=\"'+name+'_year\">');
	for (y=2037;y>=1902;y--)
	{
		if (year==y)
			document.writeln('<option selected value='+y+'>'+y+'</option>');
		else
			document.writeln('<option value='+y+'>'+y+'</option>');
	}
	document.writeln('</select>');
}
