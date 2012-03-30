use Data::Dumper;
use Term::Complete;
use Term::ReadKey;
use List::Util qw/max/;
use List::MoreUtils qw/natatime/;

my @animals = (qw(
	aardvark bear cat caterpillar chicken cow dog donkey elephant
	fox goat guinea-pig horse iguana jackal kangaroo llama monkey
	mule newt numbat octopus peacock platypus possum quail rabbit
	rat seahorse sheep shrew slug tarantula urchin vulture walrus
	), 'x-ray fish', qw(yak zebra));

sub find_animals
{
	my $string = shift;
	sort grep(/^\Q$string/, @animals);
}

sub format_choices
{
	my @choices  = @_;
	my ($wchar)  = GetTerminalSize();
	my $width    = 3 + max map { length } @choices;
	my $columns  = int( $wchar / $width ) || 1;
	my $iter     = natatime $columns, @choices;
	
	my $return = "\r\n";
	while (my @vals = $iter->())
	{
		$return .= join q(), map { sprintf("%-${width}s", $_) } @vals;
		$return .= "\r\n";
	}
	return $return;
};

my @chosen;

print "Please enter some animals. Enter a blank line to finish.\n";

while (1)
{
	my $choice = Complete("animal> ", \&find_animals, \&format_choices);
	last unless $choice =~ /[a-z]/i;
	push @chosen, $choice;
}

print Dumper \@chosen;
