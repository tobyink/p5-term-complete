use Data::Dumper;
use Term::Complete;

my @animals = (qw(
	aardvark bear cat caterpillar chicken cow dog donkey elephant
	fox goat guinea-pig horse iguana jackal kangaroo llama monkey
	mule newt numbat octopus peacock platypus possum quail rabbit
	rat seahorse sheep shrew slug tarantula urchin vulture walrus
	), 'x-ray fish', qw(yak zebra
	));

my @chosen;

print "Please enter some animals. Enter a blank line to finish.\n";

while (1)
{
	my $choice = Complete("animal> ", \@animals);
	last unless $choice =~ /[a-z]/i;
	push @chosen, $choice;
}

print Dumper \@chosen;