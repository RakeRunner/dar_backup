$dt_start = Get-Date
$dt_print = Get-Date -Format "yyyyMMdd_HHmmss"
echo "Скрипт архивации по расписанию запущен в: $dt_print"
echo "Параметры запуска: $args"
echo "args[0]: $args[0]"
echo "args[1]: $args[1]"
echo "args[2]: $args[2]"
echo "args[3]: $args[3]"
#$soft = "D:\Dar\dar.exe"

If ($args.Length -lt 3) {
			echo "Недостаточно входных аргументов!"
			echo "Использование скрипта:"
			echo " имя_скрипта.ps1 <путь_к_источнику_данных> <путь_к_месту_хранения_данных> <осн_имя_архива> [путь_к_программе_архивации]"
			echo 'Пример: .\script.ps1 "D:\Data" "E:\Backup\Data" "backup_data" "C:\DAR\dar.exe"'
			Exit
			}

If ($args.Length -gt 3) { $soft = $args[3] } #если передано более 3-х аргументов, из 4-го берём путь к dar.exe
Else {$soft = "dar"} #по умолчанию считаем, что файл dar.exe доступен через переменную %PATH% системного окружения
 

$source_path_win = $args[0] #Первым аргументом передаётся каталог, который необходимо архивировать
$source_path = "/cygdrive/" + $source_path_win 	
echo "source_path: $source_path"
$sp = ""
$i = 0
While ( $i -lt $source_path.Length) {
				Switch ($source_path.Chars($i)) 
				{
				':' {}
				'\' {$sp = $sp + '/'}
				Default {$sp = $sp + $source_path.Chars($i)
				}
						}
			$i = $i +1				 
					} #Переворачиваем слэши для dar/Cygwin

$source_path = $sp
echo "source_path: $source_path"

$dest_path_win = $args[1] #Вторым аргументом передаётся каталог, в который необходимо сохранить создаваемые архивы
$dest_path = "/cygdrive/" + $dest_path_win
echo "dest_path: $dest_path"
$sp = ""
$i = 0
While ( $i -lt $dest_path.Length) {
				Switch ($dest_path.Chars($i)) 
				{
				':' {}
				'\' {$sp = $sp + '/'}
				Default {$sp = $sp + $dest_path.Chars($i)
				}
						}
			$i = $i +1				 
					} #Переворачиваем слэши для dar/Cygwin

$dest_path = $sp
echo "dest_path: $dest_path"

$arc_name = $args[2]

$dest_path_check = $dest_path 
#$log_file = $dest_path_win + $arc_name + "_" + $dt + ".log"

$iteration = 0 #По умолчанию всегда делаем первую итерацию из расписания архивирования, то есть просто делаем полный бэкап источника

#$argslist = [string]::Concat("\-R ",$source_path, " -c ",$dest_path, $arc_name) # >> G:\BackUp\darbackup\testbackup\testbackup.log'

#$argslist = " -v -R " + $source_path + " -c " + '"' + $dest_path + $arc_name + "_" + $iteration + '"' + ' >> "G:\BackUp\darbackup\testbackup\testbackup.log"'

#echo " "
#echo $soft
#echo " "
#echo $argslist
#echo " "
#echo $log_file

#Start-Process -FilePath $soft -ArgumentList $argslist -RedirectStandardOutput $log_file

#Определяем, какие итерации архивирования уже были выполнены

#$last_file = $dest_path_win + $arc_name + "_" + $iteration + ".1.dar"
$iteration_file = $dest_path_win + "iteration"

#Определяем текущую итерацию в расписании
#Ищем файл с названием iteration_X
If (Test-Path $iteration_file)  { #Найден файл со значением предыдущей итерации

				$iteration_text = Get-Content $iteration_file #Считываем значение из файла
				$iteration = 0 + $iteration_text

	 			}
Else    { #Файл со значением предыдущей итерации не найден
	#Считаем предыдущую итерацию нулевой в расписании архивации
	#New-Item -path $dest_path_win -name "iteration" -itemtype "file" -value "0"
	$iteration = 0
	}
echo " "
echo "Считанное значение предыдущей итерации: $iteration"

If (($iteration -lt 0) -or ($iteration -gt 13)) {#Считанное из файла значение итерации не попадает в диапазон 1-13
						echo " "
						echo "Считано некорректное значение предыдущей итерации: $iteration"
						echo "Считаем текущую итерацию первой в расписании!"
						$iteration = 1
						Remove-Item $iteration_file
						New-Item -path $dest_path_win -name "iteration" -itemtype "file" -value $iteration
						}
Else    {#Считано корректное значение предыдущей итерации
	$iteration = $iteration + 1
	}

If ($iteration -eq 14) { #все итерации уже были пройдены ранее
	$iteration = 1 #уходим в начало расписания архивации; возможно, нужен ещё какой-то флаг для фиксации этого факта
	#(сделано) Добавить команды удаления соответствующих файлов; правильно определить, какие именно удалять после результатов декремента и инкремента
	$lf = $dest_path_win + $arc_name + "_" + $iteration + ".1.dar"
	#Remove-Item $lf #Удаляем старый бэкап первой итерации
		     }
echo "Текущая итерация в расписании архивации: $iteration"

#При необходимости создаём непустой заполнитель с "0" для приведения номеров архивов к двузначному виду (01, 02, 03, ..., 10, ...)
If (($iteration-1) -lt 10 ) { $filler_last = "0"} #Если предыдущая итерация была однозначной, будем добавлять к имени файла "0"
	Else {$filler_last = ""}  #Если значение предыдущей итерации было двузначным, ничего не добавляем
If ($iteration -lt 10 ) { $filler_new = "0"} #Если текущая итерация однозначная, будем добавлять к имени файла "0"
	Else {$filler_new = ""}  #Если значение текущей итерации двузначное, ничего не добавляем



$new_file = $dest_path + $arc_name + "_" + $filler_new + $iteration # + ".1.dar"
$last_file = $dest_path + $arc_name + "_" + $filler_last + ($iteration-1) # + ".1.dar"
#Определяем наличие файла с исключениями
$exclude_file = $source_path_win + "exclude.txt"
If (Test-Path $exclude_file)    {
				echo ""
				echo "Найден файл исключений $exclude_file"
				$exclude_args = " -] " + '"' + $source_path + "exclude.txt" + '"'
				echo "exclude_args: $exclude_args"
				}
Else { $exclude_args = ""}

$exclude_args = $args[4]
echo "Папки, исключаемые из архива: $exclude_args"

if ($iteration -ne 1) { echo "Файл предыдущего архива: $last_file" }
echo " "	
echo "Файл текущего архива: $new_file"


if ($iteration -le 7) { #первые 7 бэкапов в расписании - декрементные либо полные

	echo "Создаём новый полный бэкап..."
	
	$argslist = " -v -R " + '"' + $source_path + '"' + " -c " + '"' + $dest_path + $arc_name + "_" + $filler_new + $iteration + '"' + $exclude_args + ' -zgzip -wa'
	echo "argslist: $argslist"
	$log_file = $dest_path_win + $arc_name + "_" + $filler_new + $iteration + "_full" + ".log"
#	echo $log_file
	
	$process1 = (Start-Process -FilePath $soft -ArgumentList $argslist -RedirectStandardOutput $log_file  -PassThru)
	$process1.WaitForExit() #Ждём завершения процесса
	#process1.ExitCode() - можно проанализировать код завершения запущенного ранее процесса
	#Проверяем вновь созданный полный бэкап на целостность
	$dt_full_1 = Get-Date
	$dt_duration = $dt_full_1 - $dt_start
	echo " "
	echo "Полный бэкап создан за $dt_duration секунд."
	echo " "
	echo "Проверяем созданный полный бэкап на целостность..."
 	$argslist = " -t " + '"' + $dest_path + $arc_name + "_" + $filler_new + $iteration + '"'
	$log_file = $dest_path_win + $arc_name + "_" + $filler_new + $iteration + "_full_check" + ".log"
	echo $argslist
	$dt_check_start = Get-Date
	$process1 = (Start-Process -FilePath $soft -ArgumentList $argslist -RedirectStandardOutput $log_file  -PassThru)
	$process1.WaitForExit() #Ждём завершения процесса
	$dt_check_end = Get-Date
	$pr1 = $process1.ExitCode
	$dt_duration = $dt_check_end - $dt_check_start
	echo "Проверка архива на целостность завершилась с результатом: $pr1 за $dt_duration секунд."	
			
	#Создаём декрементный бэкап
        #На первой итерации делается только полный бэкап, т.о. декрементный делать не из чего
        #Изменяем аргументы запуска для создания декрементного архива
        $dec_file = $new_file + "_decremental"
	if ($iteration -ne 1) {
				$log_file = $dest_path_win + $arc_name + "_" + $filler_new + $iteration + "_decremental" + ".log"
				$argslist = " -R " + $source_path + $exclude_args + " -+ " + $dec_file + " -A " + $last_file + " -@ " + $new_file + " -ad -/ Ss -zgzip -wa"
				echo " "
				$dt_dec_start = Get-Date
				echo "Создаём декрементный бэкап..."

				$process1 = (Start-Process -FilePath $soft -ArgumentList $argslist -RedirectStandardOutput $log_file -PassThru)
                                $process1.WaitForExit() #Ждём завершения процесса
				
				$dt_dec_end = Get-Date
				$dt_duration = $dt_dec_end - $dt_dec_start

				echo " "
				echo "Декрементный бэкап создан за $dt_duration секунд."
				
				$lf = $dest_path_win + $arc_name + "_" + $filler_last + ($iteration-1) + ".1.dar"
				$df = $dest_path_win + $arc_name + "_" + $filler_new + $iteration  + "_decremental.1.dar"
				
				echo " "
				echo "Удаляем предыдущий полный бэкап..."
	                        Remove-Item $lf
				Rename-Item $df $lf
			      }
	If (Test-Path $iteration_file) { Remove-Item $iteration_file }
	New-Item -path $dest_path_win -name "iteration" -itemtype "file" -value $iteration  | out-null

		    }
Else    {
	#Итерации 8-13 - инкрементные бэкапы
	echo " "
	echo "Создаём инкрементный бэкап... "
	$log_file = $dest_path_win + $arc_name + "_" + $iteration + ".log"
	$argslist = " -R " + '"' + $source_path + '"' + " -c " + '"' + $new_file + '"' + " -A " + '"' + $last_file + '"' + " -zgzip -wa"
	echo " "
	echo "Файл предыдущего архива: $last_file"
	echo " "	
	echo "Файл текущего архива: $new_file"
	echo " "
	echo "Аргументы: $argslist"
	$dt_inc_start = Get-Date
	$process2 = (Start-Process -FilePath $soft -ArgumentList $argslist -RedirectStandardOutput $log_file -PassThru)
        $process2.WaitForExit() #Ждём завершения процесса
	$dt_inc_end = Get-Date
	$dt_duration = $dt_inc_end - $dt_inc_start
	#Фиксируем номер итерации
	echo "Инкрементный бэкап создан за $dt_duration секунд."
	echo "Код завершения: "
	Write-Host $process2.ExitCode
	Remove-Item $iteration_file
	New-Item -path $dest_path_win -name "iteration" -itemtype "file" -value $iteration | out-null

	}
$dt_finish = Get-Date
$duration = $dt_finish - $dt_start
echo " "
echo "Все операции завершены за $duration"