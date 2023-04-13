$dt = Get-Date -Format "yyyyMMdd_HHmmss"
echo "������ ��������� �� ���������� ������� �: $dt"
echo "��������� �������: $args"
echo "args[0]: $args[0]"
echo "args[1]: $args[1]"
echo "args[2]: $args[2]"
echo "args[3]: $args[3]"
#$soft = "D:\Dar\dar.exe"

If ($args.Length -lt 3) {
			echo "������������ ������� ����������!"
			echo "������������� �������:"
			echo " ���_�������.ps1 <����_�_���������_������> <����_�_�����_��������_������> <���_���_������> [����_�_���������_���������]"
			echo '������: .\script.ps1 "D:\Data" "E:\Backup\Data" "backup_data" "C:\DAR\dar.exe"'
			Exit
			}

If ($args.Length -gt 3) { $soft = $args[3] } #���� �������� ����� 3-� ����������, �� 4-�� ���� ���� � dar.exe
Else {$soft = "dar"} #�� ��������� �������, ��� ���� dar.exe �������� ����� ���������� %PATH% ���������� ���������
 

$source_path_win = $args[0] #������ ���������� ��������� �������, ������� ���������� ������������
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
					} #�������������� ����� ��� dar/Cygwin

$source_path = $sp
echo "source_path: $source_path"

$dest_path_win = $args[1] #������ ���������� ��������� �������, � ������� ���������� ��������� ����������� ������
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
					} #�������������� ����� ��� dar/Cygwin

$dest_path = $sp
echo "dest_path: $dest_path"

#$dest_path = "/cygdrive/G/BackUp/darbackup/testbackup/"

#$dest_path_win = "G:\BackUp\darbackup\testbackup\"

$arc_name = $args[2]

$dest_path_check = $dest_path 
#$log_file = $dest_path_win + $arc_name + "_" + $dt + ".log"

$iteration = 0 #�� ��������� ������ ������ ������ �������� �� ���������� �������������, �� ���� ������ ������ ������ ����� ���������

$iteration_file = $dest_path_win + "iteration"

#���������� ������� �������� � ����������
#���� ���� � ��������� iteration_X
If (Test-Path $iteration_file)  { #������ ���� �� ��������� ���������� ��������

				$iteration_text = Get-Content $iteration_file #��������� �������� �� �����
				$iteration = 0 + $iteration_text

	 			}
Else    { #���� �� ��������� ���������� �������� �� ������
	#������� ���������� �������� ������� � ���������� ���������
	#New-Item -path $dest_path_win -name "iteration" -itemtype "file" -value "0"
	$iteration = 0
	}
echo " "
echo "��������� �������� ���������� ��������: $iteration"

If (($iteration -lt 0) -or ($iteration -gt 13)) {#��������� �� ����� �������� �������� �� �������� � �������� 1-13
						echo " "
						echo "������� ������������ �������� ���������� ��������: $iteration"
						echo "������� ������� �������� ������ � ����������!"
						$iteration = 1
						Remove-Item $iteration_file
						New-Item -path $dest_path_win -name "iteration" -itemtype "file" -value $iteration
						}
Else    {#������� ���������� �������� ���������� ��������
	$iteration = $iteration + 1
	}

If ($iteration -eq 14) { #��� �������� ��� ���� �������� �����
	$iteration = 1 #������ � ������ ���������� ���������; ��������, ����� ��� �����-�� ���� ��� �������� ����� �����
	#(�������) �������� ������� �������� ��������������� ������; ��������� ����������, ����� ������ ������� ����� ����������� ���������� � ����������
	$lf = $dest_path_win + $arc_name + "_" + $iteration + ".1.dar"
	#Remove-Item $lf #������� ������ ����� ������ ��������
		     }
echo "������� �������� � ���������� ���������: $iteration"

#��� ������������� ������ �������� ����������� � "0" ��� ���������� ������� ������� � ����������� ���� (01, 02, 03, ..., 10, ...)
If (($iteration-1) -lt 10 ) { $filler_last = "0"} #���� ���������� �������� ���� �����������, ����� ��������� � ����� ����� "0"
	Else {$filler_last = ""}  #���� �������� ���������� �������� ���� ����������, ������ �� ���������
If ($iteration -lt 10 ) { $filler_new = "0"} #���� ������� �������� �����������, ����� ��������� � ����� ����� "0"
	Else {$filler_new = ""}  #���� �������� ������� �������� ����������, ������ �� ���������



$new_file = $dest_path + $arc_name + "_" + $filler_new + $iteration # + ".1.dar"
$last_file = $dest_path + $arc_name + "_" + $filler_last + ($iteration-1) # + ".1.dar"
#���������� ������� ����� � ������������
$exclude_file = $source_path_win + "exclude.txt"
If (Test-Path $exclude_file)    {
				echo ""
				echo "������ ���� ���������� $exclude_file"
				$exclude_args = " -] " + '"' + $source_path + "exclude.txt" + '"'
				echo "exclude_args: $exclude_args"
				}
Else { $exclude_args = ""}

$exclude_args = $args[4]  #���� ����������� �� ��������� �������� �� ���������� ������� �������
echo "�����, ����������� �� ������: $exclude_args"

if ($iteration -ne 1) { echo "���� ����������� ������: $last_file" }
echo " "	
echo "���� �������� ������: $new_file"


if ($iteration -le 1) { #������ ����� � ���������� - ������
        $first_arch = $dest_path_win + $arc_name + "_" + $filler_new + $iteration
	If 
	echo "������ ����� ������ �����..."
	
	$argslist = " -v -R " + '"' + $source_path + '"' + " -c " + '"' + $dest_path + $arc_name + "_" + $filler_new + $iteration + '"' + $exclude_args + ' -wa'
	echo "argslist: $argslist"
	$log_file = $dest_path_win + $arc_name + "_" + $filler_new + $iteration + "_full" + ".log"
#	echo $log_file
	
	$process1 = (Start-Process -FilePath $soft -ArgumentList $argslist -RedirectStandardOutput $log_file  -PassThru)
	$process1.WaitForExit() #��� ���������� ��������
	#process1.ExitCode() - ����� ���������������� ��� ���������� ����������� ����� ��������
	#��������� ����� ��������� ������ ����� �� �����������
	echo "��������� ��������� ������ ����� �� �����������..."
 	$argslist = " -t " + '"' + $dest_path + $arc_name + "_" + $filler_new + $iteration + '"'
	echo $argslist
	$process1 = (Start-Process -FilePath $soft -ArgumentList $argslist -RedirectStandardOutput $log_file  -PassThru)
	$process1.WaitForExit() #��� ���������� ��������
	$pr1 = $process1.ExitCode
	echo "�������� ������ �� ����������� ����������� � �����������: $pr1"	
			
	If (Test-Path $iteration_file) { Remove-Item $iteration_file }
	New-Item -path $dest_path_win -name "iteration" -itemtype "file" -value $iteration  | out-null

		    }
Else    {
	#�������� 2-13 - ������������ ������
	echo " "
	echo "������ ������������ �����... "
	$log_file = $dest_path_win + $arc_name + "_" + $iteration + ".log"
	$argslist = " -R " + '"' + $source_path + '"' + " -c " + '"' + $new_file + '"' + " -A " + '"' + $last_file + '"' + " -wa"
	echo " "
	echo "���� ����������� ������: $last_file"
	echo " "	
	echo "���� �������� ������: $new_file"
	echo " "
	echo "���������: $argslist"
	$process2 = (Start-Process -FilePath $soft -ArgumentList $argslist -RedirectStandardOutput $log_file -PassThru)
        $process2.WaitForExit() #��� ���������� ��������
	#��������� ����� ��������
	echo "��� ����������: "
	Write-Host $process2.ExitCode
	Remove-Item $iteration_file
	New-Item -path $dest_path_win -name "iteration" -itemtype "file" -value $iteration | out-null

	}
echo " "
echo "��� �������� ���������!"