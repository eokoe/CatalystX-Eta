package CatalystX::Eta::Controller::CheckRoleForPUT;

use Moose::Role;

requires 'result_PUT';

around result_PUT => sub {
    my $orig   = shift;
    my $self   = shift;
    my $config = $self->config;

    my ( $c, $id ) = @_;
    my $do_detach = 0;

    if ( !$c->check_any_user_role( @{ $config->{update_roles} } ) ) {
        $do_detach = 1;
    }

    if (
           exists $config->{object_key}
        && $c->stash->{ $config->{object_key} }
        && !$config->{check_only_roles}
        && (   $c->stash->{ $config->{object_key} }->can('id')
            || $c->stash->{ $config->{object_key} }->can('user_id')
            || $c->stash->{ $config->{object_key} }->can('created_by') )
        && $do_detach
      ) {
        my $obj = $c->stash->{ $config->{object_key} };
        my $obj_id =
            $obj->can('created_by') ? ( $obj->created_by || $obj->id )
          : $obj->can('user_id')    ? $obj->user_id
          :                           -1;    # web api user id

        my $user_id = $c->user->id;

        $self->status_forbidden( $c, message => $config->{object_key} . ".invalid [$obj_id!=$user_id]", ), $c->detach
          if $obj_id != $user_id;

        $do_detach = 0;
    }

    if ($do_detach) {
        $self->status_forbidden( $c, message => "insufficient privileges" );
        $c->detach;
    }

    $self->$orig(@_);
};

1;

