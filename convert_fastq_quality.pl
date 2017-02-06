#!/usr/bin/env perl
use strict;
use Inline 'C';
use Getopt::Long;

my $offset;
my $inFile;
my $outFile;

GetOptions(
	"offset:i"	=> \$offset,
	"in=s"	=> \$inFile,
	"out:s"	=> \$outFile
);

&usage() unless($inFile);

# default values
$offset ||= 31; # illumina phred-64 to sanger phred-33
$outFile ||= '-';


open(IN, "< $inFile") or die "Can not open $inFile:$!";
open(O, "> $outFile") or die "Can not open $outFile:$!";
my $lineCounter = 0;
my $mod;

while(<IN>)
{
	$mod = ++$lineCounter % 4;

	if(! $mod ) # score line
	{
		# modify the value of $_ in situ, avoid modify newline symbol
		_c_minus_value($_, length($_) - 1, $offset);
	}elsif($mod ==1) # first line
	{
		unless(/^@/)
		{
			warn "# Sequence name line does not start with '@'\n";
			warn ">> $_ <<\n";
			last;
		}
	}elsif($mod == 3)
	{
		unless(/^\+/)
		{
			warn "# Sequence quality line does not start with '+'\n";
			warn ">> $_ <<\n";
			last;
		}
	}

	print O;
}

close IN;
close O;

warn "# The whole work [$lineCounter lines] is done\n";

exit 0;

sub usage
{
	print <<USAGE;
Usage: $0 [options]

This program is to convert fastq quality scores by subtracting a
value (see the option --offset below).

Options:

--offset:  this is the value to be subtracted from current quality
values. Default is 31. To increase quality values, use a negative
values such as -31.

--in:  the filename of input. Mandatory option. '-' specifies the
standard input.

--out: the filename of output. Default is to standard output

Author: Zhenguo Zhang
Created: Tue Nov 25 14:00:59 EST 2014

USAGE

	exit 1;
}


#start C code

__END__

__C__

// input string, the length of string, the value to subtract from each char
void _c_minus_value(char *str, int size, int val);

void _c_minus_value(char *str, int size, int val)
{
	int i;

	for(i = 0; i < size; i++)
	{
		str[i] -= val; // modify the original data
	}

// all set
}
