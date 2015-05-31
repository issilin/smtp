package Code; 
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw/base64 quoted_printable/;
sub base64
{
	$r=pack("u",$_[0])."\n";
	$r=~s/^.||\n//mg;
	$r=~tr|` -_|AA-Za-z0-9+/|; #замена символов A заменяется на `, остальное по списку
	$t=(3-(length $_[0])%3)%3;
	$r=~s/.{$t}$//e;
	for (1..$t)
	{$r.="=";}
	$r=~s/(.{76})/$1\n/g;
	$r.="\n";
	return $r;
}
sub quoted_printable
{
	$res=$_[0];
	$eol="\n";
{ 
	$res=~s/([^ \t\n\x21-\x3C-\x3E-\x7E])/sprintf("=%02X",ord($1))/eg; #заменяем буквы 0-8;10-31 127, 61 на HEX
        $res =~s/([ \t]+)$/
          join('', map { sprintf("=%02X",ord($_))}
    		   split('', $1)
          )/egm;                        # rule #3 (encode whitespace at eol)
    }
return $res;
}
1;
