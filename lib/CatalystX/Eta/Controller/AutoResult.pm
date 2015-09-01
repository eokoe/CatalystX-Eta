package CatalystX::Eta::Controller::AutoResult;

use Moose::Role;
requires 'result_GET';
requires 'result_PUT';
requires 'result_DELETE';

around result_GET => \&AutoResult_around_result_GET;

sub AutoResult_around_result_GET {
    my $orig = shift;
    my $self = shift;
    my ($c)  = @_;

    my $it = $c->stash->{ $self->config->{object_key} };

    my $func = $self->config->{build_row};

    my $ref = $func->( $it, $self, $c );

    $self->status_ok( $c, entity => $ref );

    $self->$orig(@_);
}

around result_PUT => \&AutoResult_around_result_PUT;

sub AutoResult_around_result_PUT {
    my $orig = shift;
    my $self = shift;
    my ($c)  = @_;

    my $something = $c->stash->{ $self->config->{object_key} };

    my $data_from = $self->config->{data_from_body} ? 'data' : 'params';

    my $params = { %{ $c->req->$data_from } };
    if ( exists $self->config->{prepare_params_for_update}
        && ref $self->config->{prepare_params_for_update} eq 'CODE' ) {
        $params = $self->config->{prepare_params_for_update}->( $self, $c, $params );
    }

    $something->execute(
        $c,
        for => ( exists $c->stash->{result_put_for} ? $c->stash->{result_put_for} : 'update' ),
        with => $params,
    );

    $self->status_accepted(
        $c,
        location => $c->uri_for( $self->action_for('result'), [ @{ $c->req->captures } ] )->as_string,
        entity => { id => $something->id }
    ) if $something;

    $self->$orig(@_);

}

around result_DELETE => \&AutoResult_around_result_DELETE;

sub AutoResult_around_result_DELETE {
    my $orig      = shift;
    my $self      = shift;
    my ($c)       = @_;
    my $config    = $self->config;
    my $something = $c->stash->{ $self->config->{object_key} };

    $self->status_gone( $c, message => 'object already deleted' ), $c->detach
      unless $something;

    my $do_detach = 0;
    if ( !$c->check_any_user_role( @{ $config->{delete_roles} } ) ) {
        $do_detach = 1;
    }

    # if he does not have the role, but is the creator...
    if (
           $do_detach == 1
        && exists $config->{object_key}
        && $c->stash->{ $config->{object_key} }
        && (   $c->stash->{ $config->{object_key} }->can('id')
            || $c->stash->{ $config->{object_key} }->can('user_id')
            || $c->stash->{ $config->{object_key} }->can('created_by') )
      ) {
        my $obj = $c->stash->{ $config->{object_key} };
        my $obj_id =
            $obj->can('created_by') && defined $obj->created_by ? $obj->created_by
          : $obj->can('user_id')    && defined $obj->user_id    ? $obj->user_id
          : $obj->can('roles')      && $obj->can('id')          ? $obj->id           # user it-self.
          :                                                       -999;              # false

        my $user_id = $c->user->id;

        $self->status_forbidden( $c, message => $config->{object_key} . ".invalid [$obj_id!=$user_id]", ), $c->detach
          if $obj_id != $user_id;

        $do_detach = 0;
    }

    if ($do_detach) {
        $self->status_forbidden( $c, message => "insufficient privileges" );
        $c->detach;
    }

    $c->model('DB')->txn_do(
        sub {

            my $delete = 1;
            if ( ref $self->config->{before_delete} eq 'CODE' ) {
                $delete = $self->config->{before_delete}->( $self, $c, $something );
            }

            $something->delete if $delete;
        }
    );

    $self->status_no_content($c);
    $self->$orig(@_);
}

1;
