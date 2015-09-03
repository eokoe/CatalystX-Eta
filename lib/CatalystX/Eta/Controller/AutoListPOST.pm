package CatalystX::Eta::Controller::AutoListPOST;

use Moose::Role;

requires 'list_POST';


around list_POST => \&AutoList_around_list_POST;

sub AutoList_around_list_POST {
    my $orig = shift;
    my $self = shift;
    my ($c)  = @_;

    my $data_from = $self->config->{data_from_body} ? 'data' : 'params';

    $self->status_bad_request( $c, message => 'missing data' ), $c->detach unless ref $c->req->$data_from eq 'HASH';

    my $params = {%{ $c->req->$data_from }};
    if (
        exists $self->config->{prepare_params_for_create} &&
        ref $self->config->{prepare_params_for_create} eq 'CODE'
    ){
        $params = $self->config->{prepare_params_for_create}->($self, $c, $params);
    }

    my $something = $c->model( $self->config->{result} )->execute(
        $c,
        for => ( exists $c->stash->{list_post_for} ? $c->stash->{list_post_for} : 'create' ),
        with => {
            %$params,
            created_by => $c->user->id,
            user_id    => $c->user->id,
        }
    );

    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('result'), [ @{$c->req->captures}, $something->id ] )->as_string,
        entity => {
            id => $something->id
        }
    );

    $self->$orig(@_, $something );

    return 1;
};

1;

