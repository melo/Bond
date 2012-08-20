#!perl

use strict;
use warnings;
use Test::More;
use lib 't/tlib';
use T::Role;

subtest 'role' => sub {
  my $t = T::Role->new(id => "test.$$", role => 'agent');
  is($t->role, 'agent', 'role attr work');
};


done_testing();
