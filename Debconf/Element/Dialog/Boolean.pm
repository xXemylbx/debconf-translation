#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Dialog::Boolean - Yes/No dialog box

=cut

package Debconf::Element::Dialog::Boolean;
use strict;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This is an input element that can display a dialog box with Yes and No buttons
on it.

=cut

sub show {
	my $this=shift;

	# Note 1 is passed in, because we can squeeze on one more line
	# in a yesno dialog than in other types.
	my @params=('--yesno', $this->frontend->makeprompt($this->question, 1));
	if (defined $this->question->value && $this->question->value eq 'false') {
		# Put it at the start of the option list,
		# where dialog likes it.
		unshift @params, '--defaultno';
	}

	my ($ret, $value)=$this->frontend->showdialog(@params);
	return $ret eq 0 ? 'true' : 'false';
}

1
