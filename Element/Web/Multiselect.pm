#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Web::Multiselect - A multi select box on a form

=cut

=head1 DESCRIPTION

This element handles a multi select box on a web form.

=cut

=head1 METHODS

=cut

package Debian::DebConf::Element::Web::Multiselect;
use strict;
use Debian::DebConf::Element;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element);

=head2 show

Generates and returns html representing the multi select box.

=cut

sub show {
	my $this=shift;

	$_=$this->question->extended_description;
	s/\n/\n<br>\n/g;
	$_.="\n<p>\n";

	# Make a hash of which of the choices are currently selected.
	my %value;
	map { $value{$_} = 1 } $this->question->value_split;

	my $id=$this->id;
	$_.="<b>".$this->question->description."</b>\n<select multiple name=\"$id\">\n";
	my $c=0;
	foreach my $x ($this->question->choices_split) {
		if (! $value{$x}) {
			$_.="<option value=".$c++.">$x\n";
		}
		else {
			$_.="<option value=".$c++." selected>$x\n";
		}
	}
	$_.="</select>\n";
	
	return $_;
}

=head2 set

This gets called once the user has entered a value. It expects to be passed
all the values they selected. It processes these into the form used internally,
and saves it in the associated question.

=cut

sub set {
	my $this=shift;
	# This forces the function that provides values to this method
	# to be called in scalar context, so we are passed a list of
	# the selected values.
	my @values=@_;

	my @choices=$this->question->choices_split;
	my @parsedvalues=map { $choices[$_] } @values;

	$this->question->value(join(', ', @parsedvalues));
	$this->question->flag_isdefault('false');
}

1