#!/usr/bin/perl -w

=head1 NAME

Debconf::Base - Debconf base class

=cut

package Debconf::Base;
use strict;

=head1 DESCRIPTION

Objects of this class may have any number of fields. These fields can
be read by calling the method with the same name as the field. If a
parameter is passed into the method, the field is set.

Fields can be made up and used on the fly; I don't care what you call
them.

=head1 METHODS

=over 4

=item new

Returns a new object of this class. Optionally, you can pass in named
parameters that specify the values of any fields in the class.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $this=bless ({@_}, $class);
	$this->init;
	return $this;
}

=item init

This is called by new(). It's a handy place to set fields, etc, without
having to write your own new() method.

=cut

sub init {}

=item AUTOLOAD

Handles all fields, by creating accessor methods for them the first time
they are accessed. Lvalue is supported.

=cut

sub AUTOLOAD : lvalue {
	(my $field = our $AUTOLOAD) =~ s/.*://;

	no strict 'refs';
	*$AUTOLOAD = sub : lvalue {
		my $this=shift;

		$this->{$field}=shift if @_;
		# Ensure lvalue calls work the first time through (grr).
		$this->{$field}=undef unless exists $this->{$field};
		$this->{$field};
	};
	goto &$AUTOLOAD;
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1