;;; ol-to-bbdb.el
;; This is free software
# this is secretly a perl file, hopefully I'm not asking for trouble by
# sticking it on the emacswiki but I think it's adequately useful and wasted
# enough time trying to find something like it myself that I figure I'm 
# doing at least very little harm.
# 
# If you REALLY feel strongly that people shouldn't be able to export from 
# outlook to bbdb, you have my blessings to delete :)
#
# this script will export Outlook entries to .bbdb
#
# bug: multiple line street addresses have to be fixed up by hand

use strict;
use Win32::OLE;

sub noquotes { return 0; };
sub quotes { return 1; };
sub retnil { return 0; };
sub retempty { return 1; };

#
# have - return undef if value is undefined or empty string
#
sub have {
	return (defined $_[0] && '' ne $_[0] ? 1 : undef);
}

#
# valOrNil - return value or nil - quote value if requested
#
sub valOrNil {
	my ($fQuote, $fRetNil, $rOle) = @_;
	my $ret;

	if (defined $rOle && '' ne $rOle) {
		$ret = "\"$rOle\"" if ($fQuote == quotes);
		$ret = "$rOle" if ($fQuote == noquotes);
	} else {
		$ret = "nil" if ($fRetNil == retnil);
		$ret = "" if ($fRetNil == retempty);
	}

	return $ret;
}

#
# bbdbstr - strip newlines, escape quotes and make $_[0] bbdb friendly
#
sub bbdbstr {
	my $s = shift;
	$s =~ s/"/\\"/;
	$s =~ s/\n/\\n/;
	$s =~ s/
/\\n/;
	return $s;
}

#
# formattedPhone - return bbdb friendly phone
#
sub formattedPhone {
	my $phone = shift;
	my $reLoc = '\+?(\d*)';
	my $reArea = '\((\d*)\)';
	my $reExch = '\d+';
	my $reSufx = '\d*';
	my $reExt = '\d*';
	$phone =~ m/$reLoc *$reArea *($reExch)[- ]($reSufx)[ xX]*($reExt)/;

	return sprintf "%s %s %s %s",
	  ($2 ? $2 : "1"), # location code
	  $3, # area code
	  $4, # exchange
	  ($5 ? $5 : "0"); # extension
}

#
# export outlook to bbdb file
# bbdb format from http://bbdb.sourceforge.net/bbdb_1.html#SEC67
#
sub ol2bbdb {
    my ($ol, $mf, $c);
	$ol = Win32::OLE->new('Outlook.Application', sub {$_[0]->Quit;});
	$mf = $ol->Application->GetNamespace("MAPI")->GetDefaultFolder(10); # olFolderContacts
	print <<EOF;
;;; file-version: 6
;;; user-fields: (birthday www anniversary)
EOF

	# for some reason, collection item 0 is empty, so start at 1
	for (my $i = 1; $i < $mf->Items->Count; $i++) { # $mf->Items->Count
		$c = $mf->Items->{$i};
		my $rec = "[";

		# name
		$rec .= sprintf("%s %s %s %s", 
		  valOrNil(quotes, retnil, $c->{FirstName}),
		  valOrNil(quotes, retnil, $c->{LastName}),
		  valOrNil(quotes, retnil, $c->{NickName}),
		  valOrNil(quotes, retnil, $c->{CompanyName}));

		# phone
		if ($c->{HomeTelephoneNumber} || $c->{BusinessTelephoneNumber} || $c->{MobileTelephoneNumber}) {
			$rec .= " (";
			$rec .= sprintf(qq(["Home" %s] ), formattedPhone($c->{HomeTelephoneNumber})) if (have ($c->{HomeTelephoneNumber}));
			$rec .= sprintf(qq(["Work" %s] ), formattedPhone($c->{BusinessTelephoneNumber})) if (have $c->{BusinessTelephoneNumber});
			$rec .= sprintf(qq(["Mobile" %s] ), formattedPhone($c->{MobileTelephoneNumber})) if (have $c->{MobileTelephoneNumber});
			$rec .= ") ";
		} else {
			$rec .= " nil ";
		}
		
		# mailing address
		if ($c->{HomeAddressStreet} || $c->{BusinessAddressStreet}) {
			$rec .= " (";
			$rec .= sprintf(qq(["Home" (%s) %s %s %s %s]),
							valOrNil(quotes, retnil, $c->{HomeAddressStreet}),
							valOrNil(quotes, retnil, $c->{HomeAddressCity}),
							valOrNil(quotes, retnil, $c->{HomeAddressState}),
							valOrNil(quotes, retnil, $c->{HomeAddressPostalCode}),
							valOrNil(quotes, retnil, $c->{HomeAddressCountry})) if (have ($c->{HomeAddressStreet}));
			$rec .= sprintf(qq(["Business" (%s) %s %s %s %s]), 
							valOrNil(quotes, retnil, $c->{BusinessAddressStreet}),
							valOrNil(quotes, retnil, $c->{BusinessAddressCity}),
							valOrNil(quotes, retnil, $c->{BusinessAddressState}),
							valOrNil(quotes, retnil, $c->{BusinessAddressPostalCode}),
							valOrNil(quotes, retnil, $c->{BusinessAddressCountry})) if (have ($c->{BusinessAddressStreet}));
			$rec .= ") ";
		} else {
			$rec .= " nil ";
		}
		
		# email
		if ($c->{Email1Address} || $c->{Email2Address} || $c->{Email3Address}) {
			$rec .= " (";
			$rec .= sprintf("%s ", valOrNil(quotes, retempty, $c->{Email1Address})) if (have ($c->{Email1Address}));
			$rec .= sprintf("%s ", valOrNil(quotes, retempty, $c->{Email2Address})) if (have ($c->{Email2Address}));
			$rec .= sprintf("%s ", valOrNil(quotes, retempty, $c->{Email3Address})) if (have ($c->{Email3Address}));
			$rec .= ") ";
		} else {
			$rec .= " nil ";
		}

		# notes, etc
		$rec .= "(";
		$rec .= sprintf("(notes .\"%s\")", bbdbstr($c->{Body})) if (have $c->{Body});

		# todo: fix timestamps
		$rec .= qq((creation-date . "2003-08-03") (timestamp . "2003-08-03") );
		$rec .= sprintf("(birthday . \"%s\")", $c->{Birthday}->Date("ddd MMM dd yyyy")) if ($c->{Birthday} && '010101' ne $c->{Birthday}->Date("yyddMM"));
		$rec .= sprintf("(anniversary . \"%s\")", $c->{Anniversary}->Date("ddd MMM dd yyyy")) if ($c->{Anniversary} && '010101' ne $c->{Anniversary}->Date("yyddMM"));
		$rec .= sprintf("(www . \"%s\")", $c->{WebPage}) if (have $c->{WebPage});
		$rec .= ")";

		# footer
		$rec .= "nil]";

		print "$rec\n";
	}
	return 1;
}

#
# main
#
ol2bbdb();
;;; ol-to-bbdb.el ends here