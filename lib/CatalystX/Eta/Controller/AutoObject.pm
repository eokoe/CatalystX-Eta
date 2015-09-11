package CatalystX::Eta::Controller::AutoObject;

use Moose::Role;
requires 'object';

around object => \&AutoObject_around_object;

sub AutoObject_around_object {
    my $orig   = shift;
    my $self   = shift;
    my $config = $self->config;

    my ( $c, $id ) = @_;

    my $id_can_de_negative = $self->config->{id_can_de_negative} ? '-?' : '';
    my $primary_column = $self->config->{primary_key_column} || 'id';

    $self->status_bad_request( $c, message => 'invalid.int' ), $c->detach
      unless $id =~ /^$id_can_de_negative[0-9]+$/;

    $c->stash->{object} = $c->stash->{collection}->search( { "me.$primary_column" => $id } );
    $c->stash->{ $config->{object_key} } = $c->stash->{object}->next;

    $c->detach('/error_404') unless defined $c->stash->{ $config->{object_key} };

    $self->$orig(@_);
}

1;
