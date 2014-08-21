package NetAddr::IP::LazyInit;

use strict;
use warnings;
use NetAddr::IP qw(Zero Zeros Ones V4mask V4net Coalesce Compact netlimit);
use NetAddr::IP::Util;

our $VERSION = eval '0.3';

=head1 NAME

NetAddr::IP::LazyInit - NetAddr::IP objects with deferred validation B<SEE DESCRIPTION BEFORE USING>

=head1 VERSION

0.3

=head1 SYNOPSIS

    use NetAddr::IP::LazyInit;

    my $ip = new NetAddr::IP::LazyInit( '10.10.10.5' );

=head1 DESCRIPTION

This module is designed to quickly create objects that may become NetAddr::IP
objects.  It accepts anything you pass to it without validation.  Once a
method is called that requires operating on the value, the full NetAddr::IP
object is constructed.

You can see from the benchmarks that once you need to instantiate NetAddr::IP
the speed becomes worse than if you had not used this module.  What I mean is
that this adds unneeded overhead if you intend to do IP operations on every
object you create.

=head1 WARNING


Because validation is deferred, this module assumes you will B<only ever give
it valid data>. If you try to give it anything else, it will happily accept it
and then die once it needs to inflate into a NetAddr::IP object.


=head1 CREDITS

This module was inspired by discussion with  Jan Henning Thorsen, E<lt>jhthorsen
at cpan.orgE<gt>, and example code he provided.  The namespace and part of the
documentation/source is inspired by DateTime::LazyInit by
Rick Measham, E<lt>rickm@cpan.orgE<gt>

I didn't have to do much so I hate to take author credit, but I am providing
the module, so complaints can go to me.

Robert Drake, E<lt>rdrake@cpan.orgE<gt>

=head1 TODO

If we could actually load NetAddr::IP objects in the background while nothing
is going on that would be neat.  Or we could create shortcut methods when the
user knows what type of input he has.  new_from_ipv4('ip','mask').  We might
be able to use Socket to build the raw materials and bless a new NetAddr::IP
object without going through it's validation.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Robert Drake

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(Compact Coalesce Zero Zeros Ones V4mask V4net netlimit);

sub new { my $class = shift; bless {x=>[@_]}, $class }

sub can { NetAddr::IP->can($_[1]); }

sub addr {
    my $self = shift;
    if ($self->{x}->[0] =~ /^(.*?)(?:\/|$)/) {
        return lc($1);
    }
}

sub import {
  if (grep { $_ eq ':old_nth' } @_)
  {
    $NetAddr::IP::Lite::Old_nth = 1;
    @_ = grep { $_ ne ':old_nth' } @_;
  }
  if (grep { $_ eq ':lower' } @_)
  {
    NetAddr::IP::Util::lower();
    @_ = grep { $_ ne ':lower' } @_;
  }
  if (grep { $_ eq ':upper' } @_)
  {
    NetAddr::IP::Util::upper();
    @_ = grep { $_ ne ':upper' } @_;
  }

  NetAddr::IP::LazyInit->export_to_level(1, @_);
}

# need to support everything that NetAddr::IP does
use overload (
    '""' => sub { return $_[0]->inflate->cidr() },
    '==' => sub {
        my $a = $_[0];
        $a->inflate if ref($_[0]) =~ /NetAddr::IP::LazyInit/;
        my $b = $_[1];
        $b->inflate if ref($_[1]) =~ /NetAddr::IP::LazyInit/;
        return ($a eq $b);
    },
    'eq' => sub {
        my $a = $_[0];
        $a->inflate if ref($_[0]) =~ /NetAddr::IP::LazyInit/;
        my $b = $_[1];
        $b->inflate if ref($_[1]) =~ /NetAddr::IP::LazyInit/;
        return ($a eq $b);
    },
);

sub AUTOLOAD {
  my $self = shift;
  my $obj = NetAddr::IP->new(@{ $self->{x} });
  %$self = %$obj;
  bless $self, 'NetAddr::IP';
  our $AUTOLOAD =~ /::(\w+)$/;
  return $self->$1(@_);
}

sub inflate {
    my $self = shift;
    my $method = shift;
    my $obj = NetAddr::IP->new(@{ $self->{x} });
    %$self = %$obj;
    bless $self, 'NetAddr::IP';
    return $method ? $self->method( @_ ) : $self;
}

1;
