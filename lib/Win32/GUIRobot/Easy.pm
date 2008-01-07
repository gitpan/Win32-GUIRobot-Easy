package Win32::GUIRobot::Easy;

use 5.008008;
use strict;
use warnings;


our $VERSION = '0.01';


package ZofGUIRobot;
use strict;
use warnings;
use Carp;
use Win32::GUIRobot qw(:all);
use Win32::Clipboard;

our $VERSION = '0.01';

sub new {
    my ( $class, %args ) = @_;
    
    my $self = { PICS => {} };
    bless $self, $class;
    
    if ( ref $args{load} ) {
        if ( ref $args{load} eq 'HASH' ) {
            $self->load( $args{load} );
        }
        else {
            croak "`load` argument must be a hashref";
        }
    }
    $self->clip( Win32::Clipboard );
    
    return $self;
}

sub load {
    my ( $self, $pics_ref )= @_;
    
    keys %$pics_ref;
    my $robot_pics_ref = $self->pics;
    while ( my ( $name, $filename ) = each %$pics_ref ) {
	my $image = LoadImage( $filename );
	croak "Cannot load '$filename': $@" unless $image;

	croak "Image '$filename' is of different depth than the screen" 
		if ImageDepth( $image ) != ScreenDepth();
	croak "Image '$filename' is wider than the screen" 
		if ImageWidth( $image ) > ScreenWidth();
	croak "Image '$filename' is higher than the screen" 
		if ImageHeight( $image ) > ScreenHeight();

        $robot_pics_ref->{ $name } = $image;
        print "Loaded $name..\n";
    }
}
    
sub pics {
    my $self = shift;
    if ( @_ ) {
        $self->{ PICS } = shift;
    }
    return $self->{ PICS };
}

sub find_do {
    my ( $self, $name, $what_ref, $wait) = @_;
    croak '$what_ref must be an ARRAYREF!!'
        unless ref $what_ref eq 'ARRAY';
        
    $wait ||= 100.1;
    my $pic = $self->pics->{ $name }
        or croak "Invalid image name in find_do{}";
    my $wait_ref = WaitForImage( $pic, maxwait => $wait );
    
    unless ( ref $wait_ref and exists $wait_ref->{ok} ) {
        carp "Could not find image $name :(";
        return;
    }

    $self->do( $what_ref, @{ $wait_ref }{ qw(x y) } );
    
    return 1;
}

sub do {
    my ( $self, $what_ref, $origin_x, $origin_y ) = @_;
    $origin_x ||= 0;
    $origin_y ||= 0;
    foreach my $action ( @$what_ref ) {
        if ( ref $action eq 'HASH' ) {
            $action->{x} ||= 0;
            $action->{y} ||= 0;

            my $m_x = $origin_x + $action->{x};
            my $m_y = $origin_y + $action->{y};
            
            if ( $action->{lmb} ) {
                $self->click_mouse( $m_x, $m_y, 'Left' );
            }
            elsif ( $action->{rmb} ) {
                $self->click_mouse( $m_x, $m_y, 'Right' );
            }
            elsif ( $action->{lmbd} ) {
                $self->click_mouse( $m_x, $m_y, 'Left', 2);
            }
            elsif ( $action->{rmbd} ) {
                $self->click_mouse( $m_x, $m_y, 'Right', 2);
            }
            elsif ( $action->{mw} ) {
                MouseMoveWheel( $action->{mw} );
            }
            elsif ( $action->{drag} ) {
                $action->{d_x} ||= 0;
                $action->{d_y} ||= 0;
                MouseMoveAbsPix( $m_x, $m_y );
                SendMouse( '{LEFTDOWN}' );
                MouseMoveAbsPix(
                    $action->{d_x} + $origin_x,
                    $action->{d_y} + $origin_y,
                );
                SendMouse( '{LEFTUP}' );
            }
        }
        elsif ( ref $action eq 'ARRAY' ) {
            Sleep( $action->[0] );
        }
        elsif ( ref $action eq 'SCALAR' ) {
            $self->set_clip( $$action );
        }
        else {
            SendKeys( $action );
        }
    }
    
    return 1;    
}

sub click_mouse {
    my ( $self, $x, $y, $button, $times ) = @_;
    $times ||= 1;
    SendMouseClick( $x, $y, $button )  for 1 .. $times;
    return 1;
}

sub set_clip {
    my ( $self, $what ) = @_;
    $self->clip->Set( $what );
    return 1;
}

sub clip {
    my $self = shift;
    if ( @_ ) {
        $self->{ CLIP } = shift;
    }
    return $self->{ CLIP };
}

1;



1;
__END__

=head1 NAME

Win32::GUIRobot::Easy - A module for automating GUI tasks.

=head1 SYNOPSIS

    use Win32::GUIRobot::Easy;
    my $robot = Win32::GUIRobot::Easy->new(
        load => {
            pic1 => 'pic1.PNG',
        }
    );

    $robot->find_do( 'pic1',
        [
            \ "ZOMG!!!!.pl",
            { rmb => 1, x => 10, y => 20 },
            "{UP}{UP}~^v",
            { lmb => 1, x => 100, y => 100 },
        ]
    );

=head1 DESCRIPTION

I wrote this module because I needed to automate certain GUI tasks in a limited amount of time. Win32::GUIRobot was very helpful to me
with that, however I wanted some interface that would allow me to
write "robot instructions" more easily and quickly. This is how
Win32::GUIRobot::Easy came to existance and I want to share it with
the world, even though I do not have time to perfect it.

=head1 METHODS

=head2 new

    my $robot = Win32::GUIRobot::Easy->new;

    my $robot = Win32::GUIRobot::Easy->new(
        load => {
            pic1 => 'pic1.png',
            pic2 => 'pic2.png',
            pic3 => 'pic3.png',
        }
    );

This method creates a new Win32::GUIRobot::Easy object. You
may want to pass it an optional C<load> argument which accepts a
hashref with keys being the picture names (see C<find_do> method
below) and values being the filenames of those pictures.

=head2 load

    $robot->load( { pic1 => 'pic1.png', pic2 => 'pic2.png' } );

This method loads image(s). It takes a hashref with picure names (see C<find_do> method below) as keys and filenames as values. You 
may want to use C<load> argument to the C<new> method instead.

=head2 do

    $robot->do( [
        { lmb => 1, x => 10, y => 10 }, # click left mouse
        { rmb => 1, x => -10, y => -10 }, # right click
        { lmbd => 1, x => 10, y => 10 }, # left double click
        { mw => 2 }, # move mouse wheel.
        "{UP}{DOWN}~", # press Up, Down and Enter keys
        \ "Clip!", # copy text 'Clip!' into the clipboard
        [ 2 ], # wait for 2 seconds
    ], 400, 500 );

This method instructs your robot to do some "stuff". The first
argument is an arrayref with instructions (See ROBOT INSTRUCTIONS below for descriptions). The second and third arguments are "x origin" and "y origin" respectively. Those two values will be basically added to any 'x' and 'y' values in the
mouse related actions, they default to '0'.

=head2 find_do

    $robot->find_do( 'picture_name', # name of the picture from ->load
        [
            { lmb => 1, x => 10, y => 10 }, " left click
            "foos!" # type "foos!"
        ],
        $wait_time
    );

This method is similar to ->do method, except it first tries to find
a picture on the screen. The ->load method as well as C<load>
argument to the ->new method is where you'd get your "picture name".
The first argument to ->find_do method is picture name. The second
argument is an arrayref with instructions (see ROBOT INSTRUCTIONS
below). Third I<optional> argument is the time in seconds to wait for the picture to appear on the screen, defaults to 100. The
instructions will be passed to the ->do method when the picture is
found, and 'origin x' and 'origin y' arguments will correspond
to coordinates of where the picture was spotted.

=head1 ROBOT INSTRUCTIONS

Robot instructions are passed to ->do and ->find_do methods in the
form of an arrayref, and are executed sequentually.

Each element of the arrayref can be one of the following:

=head2 A scalar

    "{UP}^l{DOWN}~"

When an element is a scalar, the instruction will be interpreted
as a request to press some keys, it will be sent directly to
SendKeys() subroutine. See L<Win32::GuiTest> C<SendKeys> function for explanation of the keys

=head2 A scalar reference

    \ "Clipper"

When an element is a scalar reference, the content will be stuffed
into the clipboard. If you want your robot to type up a large chunk
of text, it will be significantly faster to drop that text into the
clipboard and then issue a "^v" (CTRL+V) to paste it instead of
asking the robot to type it all out key by key.

=head2 An arrayref

    [10]

When an element is an arrayref, it is interpreted as a request to
sleep for that number of seconds, the request will be passed to
C<Win32::GUIRobot::Sleep> subroutine, B<not> perl's C<sleep.

=head2 A hashref

When an element is a hashref, it is interpreted as a mouse action
(so far at least). One of the keys is an action key and the codes
for those are:

=over 5

=item lmb

Left Mouse Button

=item rmb

Right Mouse Button

=item lmbd

Left Mouse Button Double (double left click)

=item rmbd

Right Mouse Button Double (double right click)

=item mw

Mouse Wheel

=back

For all of the above, I<except mouse wheel> the value should be a
a true value. For mouse wheel the value will indicate how much to
"spin" the mouse wheel, negative values will spin in the opposite
directions. Other mouse actions take two optional arguments which
default to C<0> if not specified. The arguments are C<x> and C<y>
and the values are the offset to add to either "origin x" and
"origin y" from the ->do method, or the 'x' and 'y' coordinates of
where the picture was found from the ->find_do method.

=head1 TODO

I am planning to add support for middle button clickety soon.
Module is still in very early stage of development, expect things
to not work, work incorrectly, or not being documented :)

=head1 SEE ALSO

L<Win32::GUIRobot>, L<Win32::GuiTest>

=head1 AUTHOR

Zoffix Znet, E<lt>cpan@zoffix.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Zoffix Znet

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
