#!/usr/bin/perl -w

=head1 NAME

DebConf::FrontEnd::Noninteractive - non-interactive FrontEnd

=cut

=head1 DESCRIPTION

This FrontEnd is completly non-interactive.

=cut

=head1 METHODS

=cut
   
package Debian::DebConf::FrontEnd::Noninteractive;
use Debian::DebConf::FrontEnd;
use strict;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::FrontEnd);

print STDERR "Note: Debconf is running in non-interactive mode.\n";

# Hm, that was easy. :-)

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
