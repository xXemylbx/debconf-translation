#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Noninteractive::Note - noninteractive note Element

=cut

=head1 DESCRIPTION

This is a noninteractive note Element. Notes are generally some important peice
of information that you want the user to see sometime. Since we are running
non-interactively, we can't pause to show them. Instead, they are saved to
root's mailbox.

=cut

=head1 METHODS

=cut

package Debian::DebConf::Element::Noninteractive::Note;
use strict;
use Text::Wrap;
use Debian::DebConf::Element::Noninteractive; # perlbug
use base qw(Debian::DebConf::Element::Noninteractive);

=head2 show

Calls sendmail to mail the note to root.

=cut

sub show {
	my $this=shift;

	$this->sendmail("This note was sent to you because Debconf was asked
to make sure you saw it, but Debconf was running in noninteractive mode, or
you have told it to not pause and show you unimportant notes. Here is the text
of the note:");
	return '';
}

=head2 sendmail

The show method mails the note to root if the note has not been displayed
before. The external unix mail program is used to do this, if it is present.

If the mail is successfully sent a true value is returned.

A header may be passed as the first parameter.

=cut

sub sendmail {
	my $this=shift;
	my $header=shift;

	if (-x '/usr/bin/mail' && $this->question->flag_isdefault ne 'false') {
	    	my $title="Debconf: ".$this->frontend->title." -- ".
		   $this->question->description;
		$title=~s/'/\'/g;                                                                             # This comment here to work around stupid ' highlighting in jed
	    	open (MAIL, "|mail -s '$title' root") or return '';
		# Let's not clobber this, other parts of debconf might use
		# Text::Wrap at other spacings.
		my $old_columns=$Text::Wrap::columns;
		$Text::Wrap::columns=75;
		print MAIL wrap('', '', $header)."\n\n" if $header;
		if ($this->question->extended_description ne '') {
			print MAIL wrap('', '', $this->question->extended_description);
		}
		else {
			# Evil note!
			print MAIL wrap('', '', $this->question->description);
		}
		print MAIL "\n";
		close MAIL or return '';

		$Text::Wrap::columns=$old_columns;
	
		# Mark this note as shown. The frontend doesn't do this for us,
		# since we are marked as not visible.
		$this->question->flag_isdefault('false');

		return 1;
	}
}

1
