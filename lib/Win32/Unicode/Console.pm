package Win32::Unicode::Console;

use strict;
use warnings;
use 5.008001;
use utf8;
use Carp ();
use Win32::API ();
use Exporter 'import';

use Win32::Unicode::Encode;
use Win32::Unicode::Constant;

# export subs
our @EXPORT = qw/printW printfW warnW sayW dieW/;
our @EXPORT_OK = qw//;
our %EXPORT_TAGS = ('all' => [@EXPORT, @EXPORT_OK]);

our $VERSION = '0.06';

# GetStdHandle
my $GetStdHandle = Win32::API->new('kernel32.dll',
	'GetStdHandle',
	'N',
	'N',
) or die "GetStdHandle: $^E";

# WriteConsole
my $WriteConsole = Win32::API->new('kernel32.dll',
	'WriteConsoleW',
	[qw(N P N N P)],
	'I',
) or die "WriteConsole: $^E";

# ConsoleOut
my $ConsoleOut = sub {
	my $handle = $GetStdHandle->Call(shift);
	return 0 unless @_;
	
	return print @_ if $handle != shift;
	
	my $str = join '', @_;
	
	for (my $i = MAX_BUFFER_SIZE; $i < length($str);) {
		my $tmp_str = substr($str, 0, $i);
		substr($str, 0, $i) = '';
		
		my $buff = 0;
		$WriteConsole->Call($handle, utf8_to_utf16($tmp_str), length($tmp_str), $buff, NULL);
	}
	
	if ($str) {
		my $buff = 0;
		$WriteConsole->Call($handle, utf8_to_utf16($str), length($str), $buff, NULL);
	}
};

# print Unicode to Console
sub printW {
	if (&_is_file_handle($_[0])) {
		my $fh = shift;
		print {$fh} join "", @_;
		return 1;
	}
	
	$ConsoleOut->(STD_OUTPUT_HANDLE, CONSOLE_OUTPUT_HANDLE, @_);
	
	return 1;
}

# printf Unicode to Console
sub printfW {
	if (&_is_file_handle($_[0])) {
		my $fh = shift;
		&printW($fh, sprintf shift, @_)
	}
	
	else {
		&printW(sprintf shift, @_);
	}
}

sub _is_file_handle {
	ref $_[0] eq 'GLOB' and ref(*{$_[0]}{IO}) =~ /^IO::/ ? 1 : 0;
}

# say Unicode to Console
sub sayW {
	&printW(@_, "\n");
}

# warn Unicode to Console
sub warnW {
	$ConsoleOut->(STD_ERROR_HANDLE, CONSOLE_ERROR_HANDLE, Carp::shortmess(@_));
	return 1;
}

# die Unicode to Console
sub dieW {
	&_row_warn(@_);
	Carp::croak '';
}

sub _row_warn {
	$ConsoleOut->(STD_ERROR_HANDLE, CONSOLE_ERROR_HANDLE, @_);
}

1;
__END__
=head1 NAME

Win32::Unicode::Console.pm - Unicode string to console out

=head1 SYNOPSIS

  use Win32::Unicode::Console;
  
  my $flaged_utf8_str = "I \x{2665} Perl";
  
  printW $flaged_utf8_str;
  printfW "[ %s ] :P", $flaged_utf8_str;
  sayW $flaged_utf8_str;
  warnW $flaged_utf8_str;
  dieW $flaged_utf8_str;
  
  # write file
  printW $fh, $str;
  printfW $fh, $str;
  sayW $fh, $str;

=head1 DESCRIPTION

Win32::Unicode::Console provides Unicode String to console out.
This module is by default C<printW> and C<warnW> export functions.

This module PerlIO-proof.
However, when the file is redirected to the C<CORE:: print> and C<CORE:: warn> switches.

=head1 METHODS

=over

=item B<printW([$fh ,] @str)>

Unicode string to console out.
Like print.

=item B<printfW([$fh ,] @str)>

Unicode string to console out.
Like printf.

=item B<sayW([$fh ,] @str)>

Unicode string to console out.
Like Perl6 say.

=item B<warnW(@str)>

Unicode string to console out.
Like warn.

=item B<dieW(@str)>

Unicode string to console out.
Like die.

=back

=head1 AUTHOR

Yuji Shimada E<lt>xaicron@gmail.comE<gt>

=head1 SEE ALSO

L<Win32::API>

=cut
