package Smtp;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw/autorization datasend header link error/;
use Socket;
use Code;

sub file
{
	if (-e $_[0])
	{
		open (F, $_[0]) or die "Не удалось открыть файл\n";
	}
	else 
	{
		print STDERR "Нет файла\n";
		if ($_[1])
		{
			exit;
		}
	}
    binmode F;
    undef(local $/);
    $file = <F>;
    if ($encode eq "quoted-printable")
    {
        $encodeFile = Code::quoted_printable($file);
    }
    else
    {
        $encodeFile = Code::base64($file);
    }
}

sub header
{
	$header = "Date:".localtime."\r\n";
	$header .= "From:$_[0]\r\n";
	$header .= "X-Mailer:Мой смтп\r\n";
	$header .= "Reply-To:$_[1]\r\n";
	$header .= "X-Priority:3 (Normal)\r\n";
	$header .= "To:$_[2]\r\n";
	$header .= "Subject:$_[3]\r\n";
	$header .= "MIME-Version:1.0\r\n";
	$header .= "cc:".join(";",@{$_[4]})."\r\n";
	$header .= "bcc:".join(";",@{$_[5]})."\r\n";
	$header .= "Content-Type:multipart/mixed;boundary=New_part\r\n";
	$header .= "Content-Transfer-Encoding:8bit\r\n\r\n";
	return $header;
}

sub reads
{
	vec($rin, fileno(SMTP), 1) = 1;
	vec($win, fileno(SMTP), 1) = 1;
	$ein = $rin | $win;
    do
    {
        $buffer = <SMTP>;
		if ($buffer=~/^((4\d{2})|(5\d{2}))/)
    	{
	       	return $buffer;
    	}
    	print $buffer;
    }while(($buffer=~/(\d{3})\-/) || !(select($rout = $rin, $wout = $win, $eout = $ein, 0)));
	return 0;
}

sub autorization
{
	$LoginEncoded=Code::base64($_[0]);
	$PassEncoded=Code::base64($_[1]);
	send(SMTP, "AUTH LOGIN $LoginEncoded\r\n", 0);
	if ($err = reads)
	{
		return $err;
	}
	if ($error == 550)
	{
		print "Почтовый ящик недоступен\n";
	}
	if ($error == 553)
	{
		print "Синтаксическая ошибка в почтовом ящике\n"
	}
	send(SMTP, "$PassEncoded\r\n", 0);
	if ($err = reads)
	{
		return $err;
	}
	send(SMTP,"MAIL FROM:<$_[0]>\r\n", 0);
	if ($err = reads)
	{
		return $err;
	}
	return 0;
}

sub link
{
    $host = $_[0];
    $port = $_[1];
    $inet_addr = inet_aton($host) or die "Невозможно преобразовать хост в интернет адрес";
    $paddr = sockaddr_in($port, $inet_addr);
    socket(SMTP, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
    connect(SMTP, $paddr) or die "Невозможно соединиться $!";
    if ($err = reads)
    {
		return $err;
	}
    send(SMTP, "EHLO domain\r\n", 0);
    if ($err = reads)
    {
		return $err;
	}
	return 0;
}

sub dataSend
{
	
	$letter = $_[0];
	$header = $_[1];
	$encode = $_[2];
	$encode = "base64" unless($encode);
	@rcpt = @{$_[3]};
	@file = @{$_[4]};
	$exist = $_[5];
	$text = "";
	$text .= $header.<<EOL;
--New_part
Content-Type:text/plain
Content-Transfer-Encoding:8bit\r\n\r\n
$letter\r\n
EOL
	if (@file)
	{
        foreach (@file)
        {
        	file($_, $exist);
           	$text .= <<EOL
--New_part
Content-Type:application/octet-stream; name=\"$_\"
Content-transfer-encoding:$encode
Content-Disposition:attachment;filename=\"$_\"\r\n
$encodeFile\r\n"
EOL
        }
	}
	$text .= "--New_part--\r\n\r\n";
	foreach $rcpt (@rcpt)
	{
		chomp $rcpt;
		if ($rcpt)
		{
			send(SMTP, "RCPT TO:<$rcpt>\r\n", 0);
			$error = reads;
    		if ($error == 550)
    		{
				print "Почтовый ящик $rcpt недоступен\n";
			}
    		if ($error == 553)
    		{
				print "Синтаксическая ошибка в почтовом ящике $rcpt\n";
			}
		}
	}
	send(SMTP, "DATA\r\n", 0);
	if ($err = reads)
	{
		return $err;
	}
	send(SMTP, "$text\r\n.\r\n", 0);
	if ($err = reads)
	{
		return $err;
	}
	send(SMTP, "QUIT", 0);
	return 0;
}
1;