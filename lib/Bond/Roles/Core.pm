package Bond::Roles::Core;

use Moo::Role;
use namespace::autoclean;

requires 'BUILD';


#####################
# Peer identification

has 'id' => (is => 'ro', builder => 1);

sub _build_id {
  my $self = shift;

  return $self->generate_id if $self->can('generate_id');

  die "Attr 'id' is required for " . ref($self) . ",";
}


######################
# Initialization phase

sub init { }

after BUILD => sub { shift->init };


1;
