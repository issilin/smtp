#!/usr/bin/perl
use Getopt::Long qw(:config no_auto_abbrev);
use Socket;
use Code;
use Smtp;
sub help {
	$helpText =<<EOL;
Программа предсавляет собой Smtp клиент(клиент для отправки писем)
==================================================================
Использование: perl smtp.pl [-Ключи....]
==================================================================
Ключи:

-login		 для ввода логина
-pass 		 для ввода пароля
-port 		 для ввода порта
-rcpt 		 для ввода получателей
-host 		 для ввода хоста
-file 		 для ввода списка файлов, вводить через пробел
-from 		 для отметки от кого в загловке письма
-reply-to 	 адрес ответа.(Если отвечать нужно на другой e-mail)
-to 		 имя получателя.
-subject 	 тема бандероли
-encode 	 способ кодирования
-cc 		 копии
-bcc 		 скрытые копии. Не отображаются у получателей
-help 		 это окно;
__________________________END_____________________________________
EOL
	print $helpText;
	exit;
}
sub writting
{
	if ($mainParametersMap{'dir'})
	{
		open(F, $mainParametersMap{'dir'}) or die "Не удалось открыть письмо\n";
		$letter = <F>;
	}
	else
	{
		print "Введите текст письма:\n";
        	while(<>)
        	{
         	       $letter=$_;
        	}
	}
	$letter.="\r\n";
}

sub rcpt
{
	print "Введите получателей: ";
	@rcpt=<>;
}

sub error
{
	unless ($mainParametersMap{'error'})
	{
		$buffer = shift;
		if ($buffer =~/459/)
		{
			print STDERR "$buffer no recivers\r\n";
			exit 459;
		}

		$buffer=~s/^((4\d{2}|5\d{2}))/ERROR:/;
		print STDERR "$buffer \r\n";
	}
	exit $1;
}

sub file
{
    while  (<>)
    {
  	     print "Прикрепить файл №$i: ";
         $file[$i++]=chomp $_;
   	}
}

GetOptions(
		"exist!" => \$exist,									#если файла нет и включена то выкидывать
		"text=s" => \$mainParametersMap{'dir'}, 				#текст письма
		"error!" => \$mainParametersMap{'error'},				#отключить сообщения об ошибках
		"login=s" => \$mainParametersMap{'login'},				#логин
		"pass=s" => \$mainParametersMap{'pass'},				#пароль
		"port=i" => \$mainParametersMap{'port'},				#порт
		"rcpt=s{,}" => \@rcpt,									#получатели
		"host=s" => \$mainParametersMap{'host'},				#хост
		"file=s{,}" => \@file,									#прикрепляемые файлы
		"from=s" => \$mainParametersMap{'from'},				#адресант
		"reply-to=s" => \$mainParametersMap{'reply_to'},		#куда отсылать ответ
		"to=s" => \$mainParametersMap{'to'},					#получаетель
		"subject=s" => \$mainParametersMap{'subject'},			#тема
		"encode=s" => \$mainParametersMap{'encode'},			#способ кодирования
		"cc=s{,}" => \@cc,										#вторичные получатели
		"bcc=s{,}" => \@bcc,									#скрытые получаетели
		"help" => \$help);
eval Getoptions;

if ($@) 
{
	print "***********************$@\n";
}

print "========$SIG{__WARN__}\n";

if ($ARGV[0]=~-/\-\d*/)
{
	print "Ключ -help для вывода справки"; exit;
}

unless($mainParametersMap{'dir'} | $mainParametersMap{'host'} | $mainParametersMap{'port'} | $mainParametersMap{'login'})
{
	help;
}
if ($help) 
{
	help;
}

$mainParametersMap{'port'} ||="25";
$contentType = "text/plain";
if ($interactive)
{
	while(<>)
	{
		$command = $_;
		chomp $command;
		@arr = split(" ", $command);
		$mainParametersMap{$arr[0]} = $arr[1];
		if ($command eq "file") {file;}
		if ($command eq "rcpt") {rcpt;}
	}
}
if ($fuck = link($mainParametersMap{'host'}, $mainParametersMap{'port'}))
{
	error
};
chomp($mainParametersMap{'login'});
chomp($mainParametersMap{'pass'});
if ($mainParametersMap{'login'})
{ 
	if ($err = autorization($mainParametersMap{'login'}, $mainParametersMap{'pass'}))
	{
		error($err);
	}
}
writting;
push @rcpt, @cc;
push @rcpt, @bcc;
unless (@rcpt + 0)
{
	error('459');
}
$header = header($mainParametersMap{'from'}, $mainParametersMap{'reply_to'}, $mainParametersMap{'to'}, $mainParametersMap{'subject'}, \@cc, \@bcc);
if ($err = dataSend($pismo, $header, $mainParametersMap{'encode'}, \@rcpt, \@file, $exist))
{
	error($err);
}