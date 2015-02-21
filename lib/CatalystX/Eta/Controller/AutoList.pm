package CatalystX::Eta::Controller::AutoList;

use Moose::Role;
requires 'list_GET';
requires 'list_POST';

# inline-sub make test cover fail to compute!
around list_GET => \&AutoList_around_list_GET;

sub AutoList_around_list_GET {
    my $orig = shift;
    my $self = shift;
    my ($c)  = @_;

    #print "      AutoList::around list_GET \n";

    my $nameret = $self->config->{list_key};
    my $func = $self->config->{build_list_row} || $self->config->{build_row};

    my @rows;
    while ( my $r = $c->stash->{collection}->next ) {
        push @rows, $func->($r);
    }
    $self->status_ok(
        $c,
        entity => {
            $nameret => \@rows
        }
    );

    $self->$orig(@_);
};

around list_POST => \&AutoList_around_list_POST;

sub AutoList_around_list_POST {
    my $orig = shift;
    my $self = shift;
    my ($c)  = @_;

    my $data_from = $self->config->{data_from_body} ? 'data' : 'params';

    $self->status_bad_request( $c, message => 'missing data' ), $c->detach unless ref $c->req->$data_from eq 'HASH';

    my $something = $c->model( $self->config->{result} )->execute(
        $c,
        for  => 'create',
        with => {
            %{ $c->req->$data_from },
            created_by => $c->user->id,
            user_id    => $c->user->id,
        }
    );

    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('result'), [ $something->id ] )->as_string,
        entity => {
            id => $something->id
        }
    );

    $self->$orig(@_);

    return 1;
};

1;

