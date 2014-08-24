#!/usr/bin/perl

use strict;
use warnings;
use NetAddr::IP qw (Ones);
use NetAddr::IP::Util qw (shiftleft);
use Socket qw (inet_pton AF_INET6);
use Math::BigInt;
use lib './lib';

my $masks = {
          1 => "\200\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
          10 => "\377\300\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
          100 => "\377\377\377\377\377\377\377\377\377\377\377\377\360\0\0\0",
          101 => "\377\377\377\377\377\377\377\377\377\377\377\377\370\0\0\0",
          102 => "\377\377\377\377\377\377\377\377\377\377\377\377\374\0\0\0",
          103 => "\377\377\377\377\377\377\377\377\377\377\377\377\376\0\0\0",
          104 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\0\0\0",
          105 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\200\0\0",
          106 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\300\0\0",
          107 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\340\0\0",
          108 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\360\0\0",
          109 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\370\0\0",
          11 => "\377\340\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
          110 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\374\0\0",
          111 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\376\0\0",
          112 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\377\0\0",
          113 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\377\200\0",
          114 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\377\300\0",
          115 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\377\340\0",
          116 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\377\360\0",
          117 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\377\370\0",
          118 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\377\374\0",
          119 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\377\376\0",
          12 => "\377\360\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
          120 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\0",
          121 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\200",
          122 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\300",
          123 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\340",
          124 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\360",
          125 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\370",
          126 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\374",
          127 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\376",
          128 => "\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377",
          13 => "\377\370\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
          14 => "\377\374\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
          15 => "\377\376\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
          16 => "\377\377\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
          17 => "\377\377\200\0\0\0\0\0\0\0\0\0\0\0\0\0",
          18 => "\377\377\300\0\0\0\0\0\0\0\0\0\0\0\0\0",
          19 => "\377\377\340\0\0\0\0\0\0\0\0\0\0\0\0\0",
          2 => "\300\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
          20 => "\377\377\360\0\0\0\0\0\0\0\0\0\0\0\0\0",
          21 => "\377\377\370\0\0\0\0\0\0\0\0\0\0\0\0\0",
          22 => "\377\377\374\0\0\0\0\0\0\0\0\0\0\0\0\0",
          23 => "\377\377\376\0\0\0\0\0\0\0\0\0\0\0\0\0",
          24 => "\377\377\377\0\0\0\0\0\0\0\0\0\0\0\0\0",
          25 => "\377\377\377\200\0\0\0\0\0\0\0\0\0\0\0\0",
          26 => "\377\377\377\300\0\0\0\0\0\0\0\0\0\0\0\0",
          27 => "\377\377\377\340\0\0\0\0\0\0\0\0\0\0\0\0",
          28 => "\377\377\377\360\0\0\0\0\0\0\0\0\0\0\0\0",
          29 => "\377\377\377\370\0\0\0\0\0\0\0\0\0\0\0\0",
          3 => "\340\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
          30 => "\377\377\377\374\0\0\0\0\0\0\0\0\0\0\0\0",
          31 => "\377\377\377\376\0\0\0\0\0\0\0\0\0\0\0\0",
          32 => "\377\377\377\377\0\0\0\0\0\0\0\0\0\0\0\0",
          33 => "\377\377\377\377\200\0\0\0\0\0\0\0\0\0\0\0",
          34 => "\377\377\377\377\300\0\0\0\0\0\0\0\0\0\0\0",
          35 => "\377\377\377\377\340\0\0\0\0\0\0\0\0\0\0\0",
          36 => "\377\377\377\377\360\0\0\0\0\0\0\0\0\0\0\0",
          37 => "\377\377\377\377\370\0\0\0\0\0\0\0\0\0\0\0",
          38 => "\377\377\377\377\374\0\0\0\0\0\0\0\0\0\0\0",
          39 => "\377\377\377\377\376\0\0\0\0\0\0\0\0\0\0\0",
          4 => "\360\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
          40 => "\377\377\377\377\377\0\0\0\0\0\0\0\0\0\0\0",
          41 => "\377\377\377\377\377\200\0\0\0\0\0\0\0\0\0\0",
          42 => "\377\377\377\377\377\300\0\0\0\0\0\0\0\0\0\0",
          43 => "\377\377\377\377\377\340\0\0\0\0\0\0\0\0\0\0",
          44 => "\377\377\377\377\377\360\0\0\0\0\0\0\0\0\0\0",
          45 => "\377\377\377\377\377\370\0\0\0\0\0\0\0\0\0\0",
          46 => "\377\377\377\377\377\374\0\0\0\0\0\0\0\0\0\0",
          47 => "\377\377\377\377\377\376\0\0\0\0\0\0\0\0\0\0",
          48 => "\377\377\377\377\377\377\0\0\0\0\0\0\0\0\0\0",
          49 => "\377\377\377\377\377\377\200\0\0\0\0\0\0\0\0\0",
          5 => "\370\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
          50 => "\377\377\377\377\377\377\300\0\0\0\0\0\0\0\0\0",
          51 => "\377\377\377\377\377\377\340\0\0\0\0\0\0\0\0\0",
          52 => "\377\377\377\377\377\377\360\0\0\0\0\0\0\0\0\0",
          53 => "\377\377\377\377\377\377\370\0\0\0\0\0\0\0\0\0",
          54 => "\377\377\377\377\377\377\374\0\0\0\0\0\0\0\0\0",
          55 => "\377\377\377\377\377\377\376\0\0\0\0\0\0\0\0\0",
          56 => "\377\377\377\377\377\377\377\0\0\0\0\0\0\0\0\0",
          57 => "\377\377\377\377\377\377\377\200\0\0\0\0\0\0\0\0",
          58 => "\377\377\377\377\377\377\377\300\0\0\0\0\0\0\0\0",
          59 => "\377\377\377\377\377\377\377\340\0\0\0\0\0\0\0\0",
          6 => "\374\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
          60 => "\377\377\377\377\377\377\377\360\0\0\0\0\0\0\0\0",
          61 => "\377\377\377\377\377\377\377\370\0\0\0\0\0\0\0\0",
          62 => "\377\377\377\377\377\377\377\374\0\0\0\0\0\0\0\0",
          63 => "\377\377\377\377\377\377\377\376\0\0\0\0\0\0\0\0",
          64 => "\377\377\377\377\377\377\377\377\0\0\0\0\0\0\0\0",
          65 => "\377\377\377\377\377\377\377\377\200\0\0\0\0\0\0\0",
          66 => "\377\377\377\377\377\377\377\377\300\0\0\0\0\0\0\0",
          67 => "\377\377\377\377\377\377\377\377\340\0\0\0\0\0\0\0",
          68 => "\377\377\377\377\377\377\377\377\360\0\0\0\0\0\0\0",
          69 => "\377\377\377\377\377\377\377\377\370\0\0\0\0\0\0\0",
          7 => "\376\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
          70 => "\377\377\377\377\377\377\377\377\374\0\0\0\0\0\0\0",
          71 => "\377\377\377\377\377\377\377\377\376\0\0\0\0\0\0\0",
          72 => "\377\377\377\377\377\377\377\377\377\0\0\0\0\0\0\0",
          73 => "\377\377\377\377\377\377\377\377\377\200\0\0\0\0\0\0",
          74 => "\377\377\377\377\377\377\377\377\377\300\0\0\0\0\0\0",
          75 => "\377\377\377\377\377\377\377\377\377\340\0\0\0\0\0\0",
          76 => "\377\377\377\377\377\377\377\377\377\360\0\0\0\0\0\0",
          77 => "\377\377\377\377\377\377\377\377\377\370\0\0\0\0\0\0",
          78 => "\377\377\377\377\377\377\377\377\377\374\0\0\0\0\0\0",
          79 => "\377\377\377\377\377\377\377\377\377\376\0\0\0\0\0\0",
          8 => "\377\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
          80 => "\377\377\377\377\377\377\377\377\377\377\0\0\0\0\0\0",
          81 => "\377\377\377\377\377\377\377\377\377\377\200\0\0\0\0\0",
          82 => "\377\377\377\377\377\377\377\377\377\377\300\0\0\0\0\0",
          83 => "\377\377\377\377\377\377\377\377\377\377\340\0\0\0\0\0",
          84 => "\377\377\377\377\377\377\377\377\377\377\360\0\0\0\0\0",
          85 => "\377\377\377\377\377\377\377\377\377\377\370\0\0\0\0\0",
          86 => "\377\377\377\377\377\377\377\377\377\377\374\0\0\0\0\0",
          87 => "\377\377\377\377\377\377\377\377\377\377\376\0\0\0\0\0",
          88 => "\377\377\377\377\377\377\377\377\377\377\377\0\0\0\0\0",
          89 => "\377\377\377\377\377\377\377\377\377\377\377\200\0\0\0\0",
          9 => "\377\200\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
          90 => "\377\377\377\377\377\377\377\377\377\377\377\300\0\0\0\0",
          91 => "\377\377\377\377\377\377\377\377\377\377\377\340\0\0\0\0",
          92 => "\377\377\377\377\377\377\377\377\377\377\377\360\0\0\0\0",
          93 => "\377\377\377\377\377\377\377\377\377\377\377\370\0\0\0\0",
          94 => "\377\377\377\377\377\377\377\377\377\377\377\374\0\0\0\0",
          95 => "\377\377\377\377\377\377\377\377\377\377\377\376\0\0\0\0",
          96 => "\377\377\377\377\377\377\377\377\377\377\377\377\0\0\0\0",
          97 => "\377\377\377\377\377\377\377\377\377\377\377\377\200\0\0\0",
          98 => "\377\377\377\377\377\377\377\377\377\377\377\377\300\0\0\0",
          99 => "\377\377\377\377\377\377\377\377\377\377\377\377\340\0\0\0"
        };


use Benchmark qw (cmpthese);
# my %masks;
# for(1..128) {
#     $masks{$_}=shiftleft(Ones, 128 -$_);
# }
#
# use Data::Dumper;
# $Data::Dumper::Useqq = 1;
# $Data::Dumper::Sortkeys = 1;
# print Dumper \%masks;

my $ones = Math::BigInt->new( 2 )->bpow( 128 );

cmpthese(-3, {
    'math:;bigint' => sub {
        my ($ip, $cidr) = split('/', 'fe80::/64');
        my $mask = $ones - Math::BigInt->new( 2 )->bpow( 128 - $cidr );
        $mask = pack('N4', $mask);
        bless { 'addr' => inet_pton(AF_INET6, $ip), 'mask' => $mask, 'isv6' => 1 }, 'NetAddr::IP';
    },
    'netaddr::ip' => sub { new NetAddr::IP('fe80::/64'); },
    'shiftleft' => sub {
        my ($ip, $cidr) = split('/', 'fe80::/64');
        my $mask = shiftleft(Ones, 128 -$cidr);
        bless { 'addr' => inet_pton(AF_INET6, $ip), 'mask' => $mask, 'isv6' => 1 }, 'NetAddr::IP';
    },
    'pregenerated_mask' => sub {
        my ($ip, $cidr) = split('/', 'fe80::/64');
        my $mask = $masks->{$cidr};
        bless { 'addr' => inet_pton(AF_INET6, $ip), 'mask' => $mask, 'isv6' => 1 }, 'NetAddr::IP';
    },
    'index_substr' => sub {
        my $str = 'fe80::/64';
        my $pos = index($str,'/');
        my $ip = substr($str, 0, $pos-1);
        my $cidr = substr($str, $pos+1);
        my $mask = $masks->{$cidr};
        bless { 'addr' => inet_pton(AF_INET6, $ip), 'mask' => $mask, 'isv6' => 1 }, 'NetAddr::IP';
    },
    # for some reason inet_pton slows down if you pass it a substr() directly.
    # my $ip = substr(); is faster
    'index_substr_novariables' => sub {
        my $str = 'fe80::/64';
        my $pos = index($str,'/');
        my $ip = substr($str, 0, $pos-1);
        bless { 'addr' => inet_pton(AF_INET6, $ip), 'mask' =>  $masks->{substr($str, $pos+1)}, 'isv6' => 1 }, 'NetAddr::IP';
    },
    # This is much faster than all of the others.  It's probably worth it to
    # make a special new_ipv6_2arg function just for this case
    'nosplit' => sub {
        # mainly testing the speed of inet_pton here
        my ($ip, $cidr) = ('fe80::', '/64');
        bless { 'addr' => inet_pton(AF_INET6, $ip), 'mask' => $masks->{$cidr}, 'isv6' => 1 }, 'NetAddr::IP';
    },


});
