#!/usr/bin/perl
# Debconf db validity checker and fixer.

use strict;
use warnings;
use Debconf::Db;
use Debconf::Template;
use Debconf::Question;

# Load up all questions and templates and put them in hashes for
# ease of access.
Debconf::Db->load;

# There is no iterator method in the templates object, so I will do some nasty
# hacking to get them all. Oh well. Nothing else needs to iterate templates..
my %templates;
my $ti=$Debconf::Db::templates->iterator;
while (my $t=$ti->iterate) {
	$templates{$t}=Debconf::Template->get($t);
}
		
my %questions;
my $qi=Debconf::Question->iterator;
while (my $q=$qi->iterate) {
        $questions{$q->name}=$q;
}

# I had a report of a templates db that had templates that claimed to
# be owned by their matching questions -- but the questions didn't exist!
# Check for such a thing.

foreach my $t (keys %templates) {
	# Object has no owners method (not otherwise needed), so I'll do 
	# some nasty grubbing.
	my @owners=$Debconf::Db::templates->owners($t);
	foreach my $q (@owners) {
		if (! exists $questions{$q}) {
			print STDERR "Warning: template \"$t\" claims to be used by nonexistant question \"$q\".\n";
		}
	}
}
1
# A bug in debconf between 0.5.x and 0.9.79 caused some shared templates
# owners to not be registered. The fix is nasty; we have to load up all
# templates belonging to all installed packages all over again.
foreach my $templatefile (</var/lib/dpkg/status/*.templates>) {
	print "t: $templatefile";
}
