#!/usr/bin/perl -w

=head1 NAME

DebConf::FrontEnd::Gtk - gtk FrontEnd

=cut

=head1 DESCRIPTION

This FrontEnd is a user interface based on Gtk. It is styled on the
same lines as the Wizards in Microsoft Windows. (Be afraid..)

=cut

=head1 METHODS

=cut

package Debian::DebConf::FrontEnd::Gtk;
use Debian::DebConf::FrontEnd::Base;
use Debian::DebConf::Element::Gtk::String;
use Debian::DebConf::Element::Gtk::Boolean;
use Debian::DebConf::Element::Gtk::Select;
use Debian::DebConf::Element::Gtk::Text;
use Debian::DebConf::Element::Gtk::Note;
use Debian::DebConf::Element::Gtk::Password;
use Gtk;
use Gtk::Atoms;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::FrontEnd::Base);

use strict;

=head2 new

Creates and returns a new FrontEnd::Gtk object.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(@_), $class;

	$self->{interactive}=1;

	# create the window. If display isn't set, this dies with 
	# an untrappable error. So first tes that and exit sanely, so
	# it can be caught and fallbacks work.
	die "No DISPLAY" if $ENV{DISPLAY} eq '';
	init Gtk;

	my $window = new Gtk::Window('toplevel');
	$window->set_title("Debian Configuration Guru");
	$window->set_name("main window");
	$window->set_uposition(20,20);
	$window->set_usize(500,250);

	$window->signal_connect("destroy" => \&Gtk::main_quit);
	$window->signal_connect("delete_event" => \&Gtk::false);

	realize $window;

	# divide into three vertical sections: main, vert bar, buttons
	my $vbox = new Gtk::VBox(0,0);
	$window->add($vbox);
	$vbox->show();

	# first section is two horizontal sections: a piccie, and questions
	my $hbox = new Gtk::HBox(0,0);
	$vbox->pack_start($hbox, 1, 1, 5);
	$hbox->show;

	# the piccie has an aligned frame around it
	my $align = new Gtk::Alignment(0.5,0,0,0);
	$hbox->pack_start($align,0,0,5);
	$align->show();

	my $frame = new Gtk::Frame;
	$frame->set_shadow_type("in");

	$align->add($frame);
	$frame->show;

	# process the xpm that's in the DATA section at the end of this file.
	my @debianlogo_xpm=();
	my $pos=tell DATA;
	<DATA>;
	<DATA>;
	while (<DATA>) {
		chomp;
		s/^\"//;
		s/"};$//;
		s/",$//;
		push @debianlogo_xpm, $_;
	}
	seek DATA, 0, $pos;
	my ($debianlogo, $debianlogo_mask) = 
		Gtk::Gdk::Pixmap->create_from_xpm_d(
			$window->window,
			Gtk::Widget->get_default_style->bg('normal'),
			@debianlogo_xpm
		);

	my $pixmap = new Gtk::Pixmap($debianlogo, $debianlogo_mask);
	$frame->add($pixmap);
	show $pixmap;

	# the question frame is next
	my $questionframe = new Gtk::Frame;
	$questionframe->set_shadow_type("none");
	$hbox->pack_start($questionframe, 1, 1, 5);
	$questionframe->show();

	# okay, now we're onto the horizontal separator
	my $buttsep = new Gtk::HSeparator();
	$vbox->pack_start($buttsep, 0, 1, 0);
	$buttsep->show();

	# then the buttons at the bottom
	my $buttbox = new Gtk::HBox(0,1);
	$vbox->pack_start($buttbox, 0, 0, 5);
	$buttbox->show();

	my @butts = (new Gtk::Button("Cancel"),
	             new Gtk::Button("Next"),
	             new Gtk::Button("Back"));
	($buttbox->pack_end($_,0,0,5), $_->show) foreach (@butts);
	$butts[0]->signal_connect("clicked", sub { $self->Cancel; });
	$butts[1]->signal_connect("clicked", sub { $self->Next; });
	$butts[2]->signal_connect("clicked", sub { $self->Back; });

	$window->show();

	$self->{window} = $window;
	$self->{questionframe} = $questionframe;
	$self->{result} = "uninitialized";

	return $self;
}

=head2 makeelement

This overrides themethod in the Base FrontEnd, and creates Elements in the
Element::Gtk class. Each data type has a different Element created for it.

=cut

sub makeelement {
	my $this = shift;
	my $question = shift;

	my $type = $question->template->type;
	my $elt;
	if ($type eq 'string') {
		$elt=Debian::DebConf::Element::Gtk::String->new;
	}
	elsif ($type eq 'boolean') {
		$elt=Debian::DebConf::Element::Gtk::Boolean->new;
	}
	elsif ($type eq 'select') {
		$elt=Debian::DebConf::Element::Gtk::Select->new;
	}
	elsif ($type eq 'text') {
		$elt=Debian::DebConf::Element::Gtk::Text->new;
	}
	elsif ($type eq 'note') {
		$elt=Debian::DebConf::Element::Gtk::Note->new;
	}
	elsif ($type eq 'password') {
		$elt=Debian::DebConf::Element::Gtk::Password->new;
	}
	else {
		die "Unknown type of element: \"$type\"";
	}

	$elt->question($question);
	$elt->frontend($this);

	return $elt;
}

=head2 newques

=cut

sub newques {
	my $self = shift;
	my $newtitle = shift; # string
	my $newchild = shift; # Gtk widget

	$self->{questionframe}->remove($self->{child})
		if (defined $self->{child});

	$self->{questionframe}->add($newchild);
	$newchild->show();
	$self->{child} = $newchild;

	$self->{questionframe}->realize;

	$self->{window}->set_title("Debian Configuration Guru -- $newtitle");

	Gtk->gc;
	Gtk->main;

	return $self->{result};
}

=head2 maketext

=cut

sub maketext {
	my $self = shift;
	my $output = shift;

	my $text = new Gtk::Text(undef,undef);
	$text->insert(undef,undef,undef, "$output");
	$text->set_word_wrap(1);

	my $vscroller = new Gtk::VScrollbar($text->vadj);

	my $hbox = new Gtk::HBox(0,0);
	$hbox->pack_start($text, 1,1,0);
	$hbox->pack_start($vscroller, 0,1,0);
	$text->show();
	$vscroller->show();

	return $hbox;
}

sub Cancel {
	my $self = shift;
	$self->{result} = "cancel";
	Gtk->main_quit;
}

sub Back {
	my $self = shift;
	$self->{result} = "back";
	Gtk->main_quit;
}
sub Next {
	my $self = shift;
	$self->{result} = "change";
	Gtk->main_quit;
}

=head1 AUTHOR

Anthony Towns <aj@azure.humbug.org.au>

=cut

1

__DATA__
/* XPM */
static char * debianlogo_xpm[] = {
"114 159 45 1",
" 	c None",
".	c #F8FCF8",
"+	c #F0DCE0",
"@	c #F8ECF0",
"#	c #E8BCC8",
"$	c #D07C98",
"%	c #D88CA0",
"&	c #E09CB0",
"*	c #C04068",
"=	c #B01040",
"-	c #B82050",
";	c #A80030",
">	c #C85070",
",	c #B83058",
"'	c #C86080",
")	c #E0ACC0",
"!	c #D07088",
"~	c #F0CCD8",
"{	c #C8CCC8",
"]	c #707470",
"^	c #585C58",
"/	c #A8ACA8",
"(	c #606460",
"_	c #383C38",
":	c #989C98",
"<	c #787C78",
"[	c #404440",
"}	c #080C08",
"|	c #000400",
"1	c #D8DCD8",
"2	c #505450",
"3	c #B8BCB8",
"4	c #E8ECE8",
"5	c #181C18",
"6	c #686C68",
"7	c #282C28",
"8	c #888C88",
"9	c #202420",
"0	c #C0C4C0",
"a	c #808480",
"b	c #484C48",
"c	c #303430",
"d	c #F0F4F0",
"e	c #101410",
"f	c #D0D4D0",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"...................................................+.@#$@.#%##+...................................................",
".................................................&*=-;;>$&$-&..+&@................................................",
"..............................................+$=;;;;;;;;;,*=;;=;;>%+.............................................",
"............................................+';;;;;;;;;;;;;;;;;;;;;;;*&...........................................",
"..........................................+';;;;;;;;;;;;;;;;;;;;;;;;;;;-&+&$).....................................",
"........................................@';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;&....................................",
".......................................)=;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,!@.................................",
".....................................)';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;=)................................",
"....................................';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;!...............................",
"...................................';;;;;;;;;;;;;;;;,$>!&#.....~#$'-;;;;;;;;;;;;;;;>@.............................",
".................................@,;;;;;;;;;;;;;;;,#................~$-;;;;;;;;;;;;;,@............................",
"................................@,;;;;;;;;;;;;;;-&.....................&-;;;;;;;;;;;;,@...........................",
"...............................@,;;;;;;;;;;;;;;-%........................$;;;;;;;;;;;;,...........................",
"..............................@,;;;;;;;;;;;=!##...........................#=;;;;;;;;;;;'..........................",
"..............................>;;;;;;;;;;;>@...............................~,;;;;;;;;;;;%.........................",
".............................~;;;;;;;;;;;-+.................................@,;;;;;;;;;;=~........................",
"............................@-;;;;;;;;;;,!...................................@-;;;;;;;;;;*........................",
"............................$;;;;;;;;;*+......................................~=;;;;;;;;;;&.......................",
"...........................@=;;;;;;;;%.........................................);;;;;;;;;;-.......................",
".......................*...&;;;;;;;=~...........................................';;;;;;;;;;&......................",
"......................@-...,;;;;;;,~............................................@=;;;;;;;;;,......................",
"......................#~..%;;;;;;,@..............................................&;;;;;;;=;=+.....................",
".........................*;;;;;;=@................................................-;;;;;#.*'~.....................",
"........................#;;;;;;=~.................................................&;;;;;&.#*......................",
"........................>;;;;;;#............................~###~..................-;;;;;>.>......................",
".......................+;;;;;;%..........................&>;;;;;;='#...............!;;;;;;.&~.....................",
"....................@$.$;;;;;*.........................#-;;;;;***,;;*+.............#;;;;;;+@!.....................",
"....................&&.-;;;;;;@.......................!;;;=!~......#'-&.............;;;;;;&.$.....................",
"....................&~);;;;;;'.......................';;=$@..........@'&............*;;;;,'.&@....................",
"....................+.';;;;;;+......................%;;,+..............&~...........*;;;;=+.+#....................",
"......................=;;;;;'......................+=;*@............................%;;;;;$..~....................",
".....................);;;;;=@.....................@=;,@.............................#;;;;;'.......................",
".....................!;;;;;$......................';=+..............................#;;;;;&.......................",
".....................-;;;;;+.....................+;;$...............................#;;;;;!.......................",
".....................*;;;;-......................%;=@...............................#;;;;;=$......................",
".....................$;;;;*......................-;'................................#;;;;;;~......................",
".....................$;;;;*.....................#;;#......................'#........#;;;;;,.......................",
".....................$;;;;$.....................*;;.......................'#........);;;;;$.......................",
".....................';;;;$.....................*;-.......................~@........$;;;;-).......................",
".....................*;;;;).....................*;*.................................>;;;;'&.......................",
".....................*;;;;#.....................*;,~................................$;;;;&@~......................",
".....................*;;;;~.....................*;;#.....................+..........!;;;;&~#......................",
".....................*;;;;......................*;;%....................&%..........-;;;>&)@......................",
".....................*;;;;......................>;;!...................%)%.........#;;;;%+%.......................",
".....................*;;;;......................$;;-...................>*@........+*;;;-..%.......................",
".....................*;;;;......................~;;;~..................~&........+;;;;;&.+).......................",
".....................*;;;;.......................-;;'............................#;;;;-..&........................",
".....................*;;;;......................+!;;;+.........#$$$$.............&;;;'!..%........................",
".....................';;;;~......................!=;;*.........@&>>@............~=;;*.@.#+........................",
".....................$;;;;%....................#.$$;;;%........................~=;;;$...~.........................",
".....................$;;;;-@...................$&.%';;;&......................&;;;;,$.............................",
".....................);;;;;+...................+-%&.*;;;&..................@@$;;;;'++.............................",
".....................#;;;;;.....................%!*#~,;;;$................~>,;;;;'................................",
"......................;;;;;+.....................')*>#';;;,#.............#=;;;;;$.................................",
"......................,;;;;'......................)@*=~!;;;;*)........#&*;;;;;=)..................................",
"......................';;;;'........................@,=%&=;;;;=>$%&$'-;;;;;;;!@...................................",
"......................&;;;;-..........................!;*$;;;;;;;;;;;;;;;;='+.....................................",
"......................+;;;;;#..........................~*;,$!,;;;;;;;;;=>&@.......................................",
".......................,;;;;,@...........................&,=$@.##%$$)#+...........................................",
".......................!;;;;;=>~...........................~!-,'$)###+............................................",
".......................+;;;;;;;-@.............................+)$$$$).............................................",
"........................,;;;;;;;$.................................................................................",
"........................&;;;;;;;=@................................................................................",
"........................@=;;;;;;$~................................................................................",
".........................$;;;;;;!.................................................................................",
".........................@=;;;;;;~................................................................................",
"..........................$;;;;;;,................................................................................",
"..........................@=;;;;;*................................................................................",
"...........................%;;;;;;&...............................................................................",
"............................,;;;;;-+..............................................................................",
"............................#;;;;;;+..............................................................................",
".............................!;;;;;*..............................................................................",
"..............................,;;;;;$.............................................................................",
"..............................~=;;;;;~............................................................................",
"...............................&;;;;;-&...........................................................................",
"................................!;;;;;=@..........................................................................",
".................................';;;;;$..........................................................................",
"..................................*;;;;;~.........................................................................",
"..................................@,;;;;-##.......................................................................",
"...................................@*;;;;;=@......................................................................",
".....................................';;;;;,+.....................................................................",
"......................................!;;;;;=$....................................................................",
".......................................&=;;;;>....................................................................",
"........................................~,;;;;-#..................................................................",
"..........................................$;;;;;'!~...............................................................",
"...........................................+*;;;;;=~..............................................................",
".............................................#-;;;;=~.............................................................",
"...............................................#*;;;;$............................................................",
".................................................+!-;;-!)@........................................................",
"....................................................~%>-;;-*$)@...................................................",
"..........................................................@###+...................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
".................................................................@)...............................................",
"................................................................@,;&..............................................",
"...................{]^......................./(_...............@,;;;&.............................................",
"...............:<[}||<..................1:<2}||<..............@,;;;;;&............................................",
"...............3|||||<..................4_|||||<..............';;;;;;;+...........................................",
"................5||||<...................{|||||<..............@,;;;;;&............................................",
"................[||||3....................|||||<...............@,;;=#.............................................",
"................6||||3....................7||||<................@,=~..............................................",
"................<||||3...................._||||<.................@~...............................................",
"................<||||3...................._||||3..................................................................",
"................<||||3....................[||||3.....................4............................44..............",
"........18[_[_[62||||3......4827||_(3....._||||3..1]_[_(3.........3<93.....4/<[_[_[_]/.........43]}0.48[5|52:.....",
"......4^|||||||||||||3.....a}||||||||[4..._||||3.:|||||||(..../[5||||1...0b|||||||||||c{....db|||||3{5|||||||c4...",
".....47||||||||||||||3....^|||||||||||7..._||||3:|||||||||^....b|||||...:||||||||||||||}1....:|||||/}|||||||||^...",
".....c|||||}__7||||||3...<||||5</6}||||<..<||||/e||||||||||:.../|||||...4}||||||||||||||^....1|||||_|||||||||||4..",
"....<|||||64...15||||3..1||||74...{||||}..<||||_||567||||||5...3|||||....(||58{.../}||||}.....|||||||<4.37|||||3..",
"....}||||6......_||||...^||||1.....^||||/.<||||||^...:||||||{..{|||||..../}:.......3|||||{....}|||||8....1|||||:..",
".../||||}4......_||||...}|||7....../||||<.<|||||_.....<|||||8...|||||....41.........5||||3...._||||5......7||||<..",
"...]||||6.......[||||..3||||6......4||||b.<|||||/.....4|||||^...|||||...............[||||3....[||||6......_||||<..",
"..._||||/......._||||..<||||<.......||||_.<|||||......._||||_...|||||..............._||||3...._||||8......[||||<..",
"...|||||{......._||||..^||||3.......||||[.<||||_.......6||||[...|||||..........333337||||3...._||||3......_||||<..",
"...|||||........_||||.._||||c_[_[_[_||||_.<||||2.......<||||5...|||||......1]5|||||||||||3...._||||3......_||||<..",
"...|||||........[||||..[||||||||||||||||_.<||||<.......3||||5...|||||.....<||||||||||||||3....[||||3......_||||<..",
"...|||||........_||||.._||||||||||||||||_.<||||<.......3||||_...|||||....]||||||5___5||||3...._||||3......[||||<..",
"...|||||........_||||.._||||5___________6.<||||<.......3||||[...|||||...3|||||^1....<||||3...._||||3......_||||<..",
"...|||||1......._||||.._||||<.............<||||<.......3||||_...|||||...b||||8......_||||3...._||||3......_||||<..",
"...|||||3.......[||||.._||||<.............<||||<.......<||||<...|||||..4||||5.......[||||3....[||||3......_||||<..",
"...|||||8......._||||{.6||||^.............<||||<.......<||||/...|||||..3||||^......._||||3...._||||3......[||||<..",
"..._||||(.......7||||3.8||||9.............<||||<......._||||1...|||||..3||||<.......|||||3...._||||3......_||||<..",
"...^||||}.......|||||3.{|||||3............<||||<.......||||7....|||||..3||||(....../|||||3...._||||3......_||||<..",
"...:|||||8...../|||||3..5||||_............]||||<......:||||8....|||||..3||||5......[|||||3....[||||3......_||||<..",
"...4|||||}f...4c|||||/..<|||||^..........._||||<.....49|||}4...1|||||..{|||||/....8||||||3...._||||3......[||||<..",
"....^||||||(/85||||||<..4}|||||21.....4:2._||||<....4^||||8....3|||||...}|||||]3/_||5||||3...._||||3......_||||<..",
"....1}||||||||||5||||].../|||||||5[<2_||<._||||(3.{:5||||b.....3|||||...^||||||||||5<||||3....|||||3......_||||<..",
".....:|||||||||5<||||_....:|||||||||||||:.5|||||||||||||_4.....3|||||1..1}|||||||||3<||||:....|||||3......_||||<..",
"......:|||||||}{<|||||.....35|||||||||||31|||||||||||||<.......<|||||:...:||||||||:.<||||^...4|||||<......|||||_..",
".......1^}||5^4.:_____3....../^5||||||7^1.{<_}||||||_81........^__<b_<....{^}||}^1..:____[4..3_____<.....1__<b_[..",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
"..................................................................................................................",
".................................................................................................................."};
