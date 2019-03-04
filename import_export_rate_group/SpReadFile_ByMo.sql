select top 0 *
into #tmp
from
openrowset
(
	'microsoft.ace.oledb.12.0','excel 8.0;hdr=no;database=E:\Documents\Import_Export_Excel\Testing\02 - Format Detail_520.xlsx',
	'select top 1 * from [sheet1$]'
)

declare @cmd nvarchar(max), @line char(2) = char(13) + char(10)

select @cmd = stuff(( select concat(' alter table #tmp alter column ', name, ' nvarchar(4000)')
from tempdb.sys.columns
where object_id = object_id('tempdb..#tmp')
for xml path('')), 1, 1, '')

execute sp_executesql @cmd

insert #tmp
select *
from
openrowset
(
	'microsoft.ace.oledb.12.0','excel 8.0;hdr=no;database=E:\Documents\Import_Export_Excel\Testing\02 - Format Detail_520.xlsx',
	'select * from [sheet1$]'
)

delete top (1) from #tmp

select @cmd =
			stuff(( 
					select @line, 'update #tmp set ' + name + ' = ltrim(rtrim(' + name + '))'
					from tempdb.sys.columns 
					where object_id = object_id('tempdb..#tmp') 
					for xml path(''), type).value('.', 'nvarchar(max)'), 1, 1, '')
execute sp_executesql @cmd

select @Out =
(
	select row_number() over (order by (select 0)) as Sequence, *
	from #tmp
	for xml raw('Elements'), root('Root')
)

select @Count = count(1)
from tempdb.sys.columns
where object_id = object_id('tempdb..#tmp')