#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Slang::String - text input widget

=cut
                
=head1 DESCRIPTION

This is a text input widget.

=cut

package Debian::DebConf::Element::Slang::String;
use strict;
use Term::Stool::Input;
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element);

sub makewidget {
	my $this=shift;
	my $yoffset=shift;

	my $default='';
	$default=$this->question->value if defined $this->question->value;
	$this->widget(Term::Stool::Input->new(
		text => $default,
	));
}

=head2 resize

This is called when the widget is resized.

Try to make the text box 20 characters wide at a minimum. If there's room
for a text box that wide to fix on the same line as the description, do so.
Otherwise, put the text box on the next line.

=cut

sub resize {
	my $this=shift;
	my $widget=$this->widget;
	my $description=$widget->description;
	my $maxwidth=$widget->container->width - 4;

	if ($maxwidth > 20 + $description->width) {
		$widget->sameline(1);
		$widget->width($maxwidth - 1 - $description->width);
		$widget->xoffset($description->width + 2);
	}
	else {
		$widget->sameline(0);
		$widget->width($maxwidth);
		$widget->xoffset(1);
	}
}

sub value {
	my $this=shift;

	return $this->widget->text;
}

1
