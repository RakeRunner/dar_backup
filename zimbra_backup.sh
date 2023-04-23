#!/bin/bash

if [ $# -lt 3 ]; then
        echo "Недостаточно входных данных для использования скрипта $0";
	echo "Использование скрипта:";
	echo "$0 <путь_к_источнику_данных> <путь_к_месту_хранения_данных> <осн_имя_архива> [путь_к_программе_архивации]"
	echo "Пример: $0 '/home/user/downloads' '/media/reserv' 'backup_data' 'dar'"
	echo "Исключения необходимо указать в файле exclude.txt, и разместить его в корне архивируемого каталога."
	echo "Завершение работы"
	exit;
#    else
#        ls|grep "$1"|sed ... | wc -l
fi

dt_start=`date +%s` #запоминаем время запуска скрипта
source_path=$1 # Что архивируем
dest_path=$2 # Куда архивируем
arc_name=$3 # Как называем итоговый архив
iteration_file=$2'/iteration'

subject="[DAR] Создание архива "$arc_name" запущено в "`date +%H:%M:%S`" "`date +%d-%m-%C%y`

echo -e '\n'"Subject: $subject"'\n'

body="Дождитесь сообщения о завершении архивации. В случае длительного отсутствия сообщения, проверьте логи на сервере."

/usr/bin/sendEmail -f 'informer@tehkom.su' -t 'vadim@tehkom.su' -o message-charset=utf-8  -u $subject -m $body -s 'mail.tehkom.su' -o tls=yes # -xu $SMTPLOGIN -xp $SMTPPASS

su - zimbra -c "zmcontrol stop" # Stopping zimbra

iteration=0 #По умолчанию всегда делаем первую итерацию из расписания архивирования, то есть просто делаем полный бэкап источника

echo -e "Скрипт архивации каталога $source_path запущен в " $dt_start '\n'
echo "Имя архива: $3"
echo "Каталог назначения: $2"
echo "Файл хранения значения итерации: $iteration_file"

#Определяем текущую итерацию в расписании
#Ищем файл с названием iteration в каталоге назначения
if [ ! -f $iteration_file ]
then
    echo "Файл значения предыдущей итерации $iteration_file не найден"
    iteration=0
else
    #read $iteration < $iteration_file
    iteration=`tail -n 1 $iteration_file`
    echo "Считанное значение предыдущей итерации: $iteration"
fi

if [ $iteration -lt 0 ] || [ $iteration -gt 13 ] 
then #Считанное из файла значение итерации не попадает в диапазон 1-13
	echo " "
	echo "Считано некорректное значение предыдущей итерации: $iteration"
	echo "Считаем текущую итерацию первой в расписании!"
	iteration=1
	rm $iteration_file #удаляем файл с некорректным значением
	touch $iteration_file #создаем пустой файл
	echo $iteration > $iteration_file #записываем туда значение 1
	#New-Item -path $dest_path_win -name "iteration" -itemtype "file" -value $iteration
else #Считано корректное значение предыдущей итерации
	let "iteration = iteration + 1"
#	echo "Текущая итерация в расписании: $iteration"
fi


if [ $iteration -eq 14 ] 
then  #все итерации уже были пройдены ранее
	iteration=1 #уходим в начало расписания архивации; возможно, нужен ещё какой-то флаг для фиксации этого факта
	#(сделано) Добавить команды удаления соответствующих файлов; правильно определить, какие именно удалять после результатов декремента и инкремента
	lf=$dest_path$arc_name'_'$iteration'.1.dar'
	#Remove-Item $lf #Удаляем старый бэкап первой итерации
fi

echo "Текущая итерация в расписании архивации: $iteration"

#При необходимости создаём непустой заполнитель с "0" для приведения номеров/файлов архивов к двузначному виду (01, 02, 03, ..., 10, ...)
if [ $iteration -lt 11 ] 
then 
     filler_last="0" #Если предыдущая итерация была односимвольной, будем добавлять к имени файла "0"
else 
    filler_last="" 
fi  #Если значение предыдущей итерации было двухсимвольной, ничего не добавляем

if [ $iteration -lt 10 ] 
then 
    filler_new="0" #Если текущая итерация односимвольная, будем добавлять к имени файла "0"
else 
    filler_new="" 
fi  #Если значение текущей итерации двухсимвольная, ничего не добавляем


new_file=$dest_path'/'$arc_name'_'$filler_new$iteration # + ".1.dar"
echo "Файл текущего архива: $new_file"

let "prev_int = iteration - 1"
last_file=$dest_path'/'$arc_name'_'$filler_last$prev_int #+ ".1.dar"
echo "Файл предыдущего архива: $last_file"

#Определяем наличие файла с исключениями
exclude_file=$source_path'/exclude.txt'
echo "Exclude file: $exclude_file"

if [ ! -f $exclude_file ]
then
    echo "Файл исключений в исходном каталоге не найден"
    exclude_args="" #Ничего не исключаем при архивации
else
    echo "Найден файл исключений $exclude_file"
    exclude_args=' -] '$exclude_file
    echo "exclude_args: $exclude_args"
fi

if [ $iteration -le 7 ] #первые 7 бэкапов в расписании - декрементные либо полные
then 
    echo "Создаём новый полный бэкап..."
    log_file=$dest_path'/'$arc_name'_'$filler_new$iteration'_full.log'
    dar -v -R $source_path -c $new_file $exclude_args -zgzip -wa > $log_file #Лог создания записываем в отдельный файл
    dt_full1=`date +%s` #Определяем текущее время
    let "dt_duration = dt_full1 - dt_start"
    echo "Полный бэкап создан за $dt_duration секунд"
    echo "Проверяем созданный бэкап на целостность:"
    dt_check_start=`date +%s`
    dar -t $new_file
    dt_check_end=`date +%s`
    let "dt_duration = dt_check_end - dt_check_start"
    echo "Проверка архива на целостность завершилась за $dt_duration секунд"
    
    #Теперь создаем декрементный бэкап
    #При этом на первой итерации выполняется только полный бэкап, т.к. декрементный делать не из чего
    
    ## ВАЖНО! Для декрементного бэкапа нужны два полных бэкапа - текущий и предыдущий. 
    ## Поэтому внимательно контролируем свободное место на диске назначения при резервировании больших объемов!
    
    #Изменяем аргументы запуска для создания декрементного архива
    dec_file=$new_file.decremental

    if [ $iteration -ne 1 ] 
    then #Убеждаемся, что итерация не первая
	log_file=$dec_file'.log'
	dt_dec_start=`date +%s` #Определяем текущее время
	echo "Создаем декрементный бэкап..."
	
	dar -R $source_path $exclude_args -+ $dec_file -A $last_file -@ $new_file -ad -/ Ss -zgzip -wa
	
	dt_dec_end=`date +%s` #Определяем текущее время
	let "dt_duration = dt_dec_end - dt_dec_start"
	echo "Декрементный бэкап создан за $dt_duration секунд"
	
	echo "Удаляем предыдущий полный бэкап..."
	rm $last_file".1.dar" #Удаляем предыдущий полный бэкап
	mv $dec_file".1.dar" $last_file".1.dar" #Переименовываем декрементный архив
    fi

    #Обновляем значение итерации в соответствующем файле
    echo $iteration > $iteration_file
else
   #Итерации 8-13 - инкрементные бэкапы
   echo -e "Создаём инкрементный бэкап..." '\n'
   log_file=$new_file".log"
   echo "log_file: $log_file"
   echo -e "Файл предыдущего архива: " $last_file '\n'
   echo -e "Файл текущего архива: " $new_file '\n'
   dt_inc_start=`date +%s` #Определяем текущее время
   
   #Запускаем собственно архиватор
   dar -R $source_path -c $new_file -A $last_file -zgzip -wa
   
   dt_inc_end=`date +%s` #Определяем текущее время
   let "dt_duration = dt_inc_end - dt_inc_start"
   echo -e "Инкрементный бэкап выполнен за $dt_duration секунд" '\n'
    
    #Обновляем значение итерации в соответствующем файле
    echo $iteration > $iteration_file
   
fi
dt_finish=`date +%s` #Определяем текущее время
let "dt_duration = dt_finish - dt_start"
echo -e "Все операции завершены за $duration секунд"
su - zimbra -c "zmcontrol start" # Starting zimbra

# Sending result email
subject="[DAR] Создание архива "$arc_name" завершено в $dt_finish"

echo -e '\n'"Subject: $subject"'\n'

body="Работа почтового сервера Zimbra возобновлена после архивации. Проверьте логи на сервере."


/usr/bin/sendEmail -f 'informer@tehkom.su' -t 'vadim@tehkom.su' -o message-charset=utf-8  -u $subject -m $body -s 'mail.tehkom.su' -o tls=yes # -xu $SMTPLOGIN -xp $SMTPPASS
