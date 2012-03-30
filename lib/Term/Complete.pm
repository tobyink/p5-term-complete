package Term::Complete;
require 5.000;
require Exporter;

use strict;
our @ISA = qw(Exporter);
our @EXPORT = qw(Complete);
our $VERSION = '1.402';

#      @(#)complete.pl,v1.2            (me@anywhere.EBay.Sun.COM) 09/23/91

=head1 NAME

Term::Complete - Perl word completion module

=head1 SYNOPSIS

    $input = Complete('prompt_string', \@completion_list);
    $input = Complete('prompt_string', \&completion_list);
    $input = Complete('prompt_string', @completion_list);

=head1 DESCRIPTION

This routine provides word completion on the list of words in
the array or array ref.

If a reference to a sub is provided, that sub will be called with
the word typed so far passed as its argument, and is expected to
return a completion list.

When the completion list is provided as a code ref or array ref,
C<Complete> accepts an optional third parameter, a formatter code
ref. When the user presses C<< ^D >> to see a list of choices,
this formatter will be called with a list of words, and is expected
to join them into a string to be printed. The default formatter
formats the words one per line.

=head2 Internals

The tty driver is put into raw mode and restored using an operating
system specific command, in UNIX-like environments C<stty>.

The following command characters are defined:

=over 4

=item E<lt>tabE<gt>

Attempts word completion.
Cannot be changed.

=item ^D

Prints completion list.
Defined by I<$Term::Complete::complete>.

=item ^U

Erases the current input.
Defined by I<$Term::Complete::kill>.

=item E<lt>delE<gt>, E<lt>bsE<gt>

Erases one character.
Defined by I<$Term::Complete::erase1> and I<$Term::Complete::erase2>.

=back

=head1 DIAGNOSTICS

Bell sounds when word completion fails.

=head1 BUGS

The completion character E<lt>tabE<gt> cannot be changed.

=head1 AUTHOR

Wayne Thompson

=cut

our ($complete, $kill, $erase1, $erase2, $tty_raw_noecho, $tty_restore, $stty, $tty_safe_restore);
our ($tty_saved_state) = '';
CONFIG: {
    $complete = "\004";
    $kill     = "\025";
    $erase1 =   "\177";
    $erase2 =   "\010";
    foreach my $s (qw(/bin/stty /usr/bin/stty)) {
        if (-x $s) {
            $tty_raw_noecho = "$s raw -echo";
            $tty_restore    = "$s -raw echo";
            $tty_safe_restore = $tty_restore;
            $stty = $s;
            last;
        }
    }
}

sub Complete {
    my $prompt = shift;
    
    my ($cmp_lst, $formatter);
    
    if (ref $_[0] eq 'CODE') {
        ($cmp_lst, $formatter) = @_;
    }
    else {
        my @cmp_lst = do {
            if (ref $_[0] eq 'ARRAY' || $_[0] =~ /^\*/) {
                $formatter = $_[1];
                sort @{$_[0]};
            }
            else {
                sort(@_);
            }
        };
        
        $cmp_lst = sub {
            my $partial = shift;
            grep(/^\Q$partial/, @cmp_lst);
        }
    }
    
    if (ref $formatter ne 'CODE') {
        $formatter = sub { join("\r\n", '', @_) . "\r\n" };
    }
    
    my ($return, $r) = ("", 0);
    
    # Attempt to save the current stty state, to be restored later
    if (defined $stty && defined $tty_saved_state && $tty_saved_state eq '') {
        $tty_saved_state = qx($stty -g 2>/dev/null);
        if ($?) {
            # stty -g not supported
            $tty_saved_state = undef;
        }
        else {
            $tty_saved_state =~ s/\s+$//g;
            $tty_restore = qq($stty "$tty_saved_state" 2>/dev/null);
        }
    }
    system $tty_raw_noecho if defined $tty_raw_noecho;
    LOOP: {
        local $_;
        print($prompt, $return);
        while (($_ = getc(STDIN)) ne "\r") {
            CASE: {
                # (TAB) attempt completion
                $_ eq "\t" && do {
                    my @match = $cmp_lst->($return);
                    unless ($#match < 0) {
                        my $l = length(my $test = shift(@match));
                        foreach my $cmp (@match) {
                            until (substr($cmp, 0, $l) eq substr($test, 0, $l)) {
                                $l--;
                            }
                        }
                        print("\a");
                        print($test = substr($test, $r, $l - $r));
                        $r = length($return .= $test);
                    }
                    last CASE;
                };
                
                # (^D) completion list
                $_ eq $complete && do {
                    print $formatter->( $cmp_lst->($return) );
                    redo LOOP;
                };
                
                # (^U) kill
                $_ eq $kill && do {
                    if ($r) {
                        $r       = 0;
                        $return  = "";
                        print("\r\n");
                        redo LOOP;
                    }
                    last CASE;
                };
                
                # (DEL) || (BS) erase
                ($_ eq $erase1 || $_ eq $erase2) && do {
                    if($r) {
                        print("\b \b");
                        chop($return);
                        $r--;
                    }
                    last CASE;
                };
                
                # printable char
                ord >= 32 && do {
                    $return .= $_;
                    $r++;
                    print;
                    last CASE;
                };
            }
        }
    }
    
    # system $tty_restore if defined $tty_restore;
    if (defined $tty_saved_state && defined $tty_restore && defined $tty_safe_restore)
    {
        system $tty_restore;
        if ($?) {
            # tty_restore caused error
            system $tty_safe_restore;
        }
    }
    print("\n");
    $return;
}

1;
