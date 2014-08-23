package NetAddr::IP::LazyInit;

use strict;
use warnings;
use NetAddr::IP qw(Zero Zeros Ones V4mask V4net netlimit);
use Socket qw(inet_pton AF_INET AF_INET6);
use NetAddr::IP::Util;

our $VERSION = eval '0.4';

=head1 NAME

NetAddr::IP::LazyInit - NetAddr::IP objects with deferred validation B<SEE DESCRIPTION BEFORE USING>

=head1 VERSION

0.4

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

# local copy for our functions because otherwise it takes 717ns/call to reference
my $ones = &Ones;
# this is to zero the ipv6 portion of the address
my $zerov6 = pack('n6', (0,0,0,0,0,0));

sub new { my $class = shift; bless {x=>[@_]}, $class }

=head1 METHODS

=head2 new_ipv4

Create a real NetAddr::IP from a single IPv4 address with almost no
validation.  This has more overhead than the LazyInit new() but it's much
faster if you make use of the IP object.

This only takes one argument, the single IP address.  Anything else will fail
in (probably) bad ways.  Validation is completely up to you and is not done
here.

   my $ip = NetAddr::IP::LazyInit->new_ipv4("127.0.0.1");

=cut


sub new_ipv4 {
    return bless {
        addr    => $zerov6 . inet_pton(AF_INET, $_[1]),
        mask    => $ones,
        isv6    => 0,
    }, 'NetAddr::IP';
}

=head2 new_ipv4_mask

Create a real NetAddr::IP from a IPv4 subnet with almost no
validation.  This has more overhead than the LazyInit new() but it's much
faster if you make use of the IP object.

This requires the IP address and the subnet mask as it's two arguments.
Anything else will fail in (probably) bad ways.  Validation is completely
up to the caller is not done here.

   my $ip = NetAddr::IP::LazyInit->new_ipv4_mask("127.0.0.0", "255.255.255.0");

=cut


sub new_ipv4_mask {
    return bless {
        addr    => $zerov6 . inet_pton(AF_INET, $_[1]),
        mask    => $zerov6 . inet_pton(AF_INET, $_[2]),
        isv6    => 0,
    }, 'NetAddr::IP';
}

sub can { NetAddr::IP->can($_[1]); }

sub Compact {
    for (@_) {
        $_->inflate if (ref($_) eq 'NetAddr::IP::LazyInit');
    }
    return NetAddr::IP::Compact(@_);
}



sub Coalesce {
    for (@_) {
        $_->inflate if (ref($_) eq 'NetAddr::IP::LazyInit');
    }
    return NetAddr::IP::Coalesce(@_);
}

sub addr {
    my $self = shift;
    if ($self->{x}->[0] =~ /^(.*?)(?:\/|$)/) {
        return lc($1);
    }
}

sub mask {
    my $self = shift;
    if ($self->{x}->[1] && $self->{x}->[1] =~ /\D/) {
        return $self->{x}->[1];
    } else {
        return $self->inflate->mask;
    }
}

sub import {
    if (grep { $_ eq ':rfc3021' } @_)
    {
        $NetAddr::IP::rfc3021 = 1;
        @_ = grep { $_ ne ':rfc3021' } @_;
    }
    if (grep { $_ eq ':old_storable' } @_) {
        @_ = grep { $_ ne ':old_storable' } @_;
    }
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
    '@{}'   => sub { return [ $_[0]->inflate->hostenum ]; },
    '""'    => sub { return $_[0]->inflate->cidr() },
    '<=>'   => sub { inflate_args_and_run(\&NetAddr::IP::Lite::comp_addr_mask, @_); },
    'cmp'   => sub { inflate_args_and_run(\&NetAddr::IP::Lite::comp_addr_mask, @_); },
    '++'    => sub { inflate_args_and_run(\&NetAddr::IP::Lite::plusplus, @_); },
    '+'     => sub { inflate_args_and_run(\&NetAddr::IP::Lite::plus, @_); },
    '--'    => sub { inflate_args_and_run(\&NetAddr::IP::Lite::minusminus, @_); },
    '-'     => sub { inflate_args_and_run(\&NetAddr::IP::Lite::minus, @_); },
    '='     => sub { inflate_args_and_run(\&NetAddr::IP::Lite::copy, @_); },
    '=='    => sub {
        my $a = $_[0];
        $a->inflate if ref($_[0]) =~ /NetAddr::IP::LazyInit/;
        my $b = $_[1];
        $b->inflate if ref($_[1]) =~ /NetAddr::IP::LazyInit/;
        return ($a eq $b);
    },
    '!='    => sub {
        my $a = $_[0];
        $a->inflate if ref($_[0]) eq 'NetAddr::IP::LazyInit';
        my $b = $_[1];
        $b->inflate if ref($_[1]) eq 'NetAddr::IP::LazyInit';
        return ($a ne $b);
    },
    'ne'    => sub {
        my $a = $_[0];
        $a->inflate if ref($_[0]) eq 'NetAddr::IP::LazyInit';
        my $b = $_[1];
        $b->inflate if ref($_[1]) eq 'NetAddr::IP::LazyInit';
        return ($a ne $b);
    },
    'eq'    => sub {
        my $a = $_[0];
        $a->inflate if ref($_[0]) eq 'NetAddr::IP::LazyInit';
        my $b = $_[1];
        $b->inflate if ref($_[1]) eq 'NetAddr::IP::LazyInit';
        return ($a eq $b);
    },
    '>'     => sub { return &comp_addr_mask > 0 ? 1 : 0; },
    '<'     => sub { return &comp_addr_mask < 0 ? 1 : 0; },
    '>='    => sub { return &comp_addr_mask < 0 ? 0 : 1; },
    '<='    => sub { return &comp_addr_mask > 0 ? 0 : 1; },

);

sub comp_addr_mask {
    return inflate_args_and_run(\&NetAddr::IP::Lite::comp_addr_mask, @_);
}

sub inflate_args_and_run {
    my $func = shift;
    $_[0]->inflate if ref($_[0]) eq 'NetAddr::IP::LazyInit';
    $_[1]->inflate if ref($_[1]) eq 'NetAddr::IP::LazyInit';
    return &{$func}(@_);
}

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
