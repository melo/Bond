#!perl

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use lib 't/tlib';
use T::Core;
use T::CoreWithGenId;


subtest 'id' => sub {
  my $t1 = T::Core->new(id => "test.$$");
  is($t1->id, "test.$$", 'id attr work');

  my $t2 = T::CoreWithGenId->new;
  is($t2->id, $$, 'id attr via generate_id() work');

  like(exception { T::Core->new }, qr{^Attr 'id' is required for }, 'proper exception if ID not given');
};


subtest 'init' => sub {
  my $t = T::CoreWithGenId->new;
  is($t->called, 1, 'init() was called properly');
};


done_testing();
