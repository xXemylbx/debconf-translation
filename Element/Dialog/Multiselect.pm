#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Dialog::Multiselect - a check list in a dialog box

=cut

=head1 DESCRIPTION

This is an input element that can display a dialog box with a check list in
it.

=cut

package Debian::DebConf::Element::Dialog::Multiselect;
use strict;
use Debian::DebConf::Element;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element);

sub show {
	my $this=shift;

	# Figure out how much space in the dialog box the prompt will take.
	my ($text, $lines, $columns)=
		$this->frontend->makeprompt($this->question);

	my $screen_lines=$this->frontend->screenheight - $this->frontend->spacer;
	my $default='';
	$default=$this->question->value if defined $this->question->value;
	my @params=();
	my @choices=$this->question->choices_split;
	# Make a hash of which of the choices are currently selected.
	my %value;
	map { $value{$_} = 1 } $this->question->value_split;
		
	# Figure out how many lines of the screen should be used to
	# scroll the list. Look at how much free screen real estate
	# we have after putting the description at the top. If there's
	# too little, the list will need to scroll.
	my $menu_height=$#choices + 1;
	if ($lines + $#choices + 2 >= $screen_lines) {
		$menu_height = $screen_lines - $lines - 4;
		if ($menu_height < 3 && $#choices + 1 > 2) {
			# Don't display a tiny menu.
			$this->frontend->showtext($this->question->extended_description);
			($text, $lines, $columns)=$this->frontend->sizetext($this->question->description);
			$menu_height=$#choices + 1;
			if ($lines + $#choices + 2 >= $screen_lines) {
				$menu_height = $screen_lines - $lines - 4;
			}
		}
	}
	
	$lines=$lines + $menu_height + $this->frontend->spacer;
	my $c=1;
	foreach (@choices) {
		push @params, ($_, "");
		push @params, ($value{$_} ? 'on' : 'off');
		
	}
	
	@params=('--checklist', $text, $lines, $columns, $menu_height, @params);

	my ($ret, $value)=$this->frontend->showdialog(@params);

	exit $ret if $ret != 0;

	# Dialog returns a list of the selected items, quoted, with spaces
	# in between. Parse that and change it into the style we use
	# internally.
	$value=~s/^"//;
	$value=~s/"\s*$//;
	$value=~s/" "/, /g;

	$this->question->value($value);
	$this->question->flag_isdefault('false');
}

1
