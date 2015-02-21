# NAME

CatalystX::Eta are composed of Moose::Roles for consistent CRUD/Validation/Testing between apps.

"Eta" is just a cool Greek letter. I'm using it for not polluting CPAN CatalystX namespace with this module.

# WTH CatalystX::Eta is and why did you do that

I started (although not with this namespace) as set of Catalyst Controller Roles to extend and reduce
repeatable tasks that I had to do to make REST/CRUD stuff.

Later, I had to start more Catalyst projects. After a while, others collaborators were using it
on their projects too, but copying the code in each app.

After a while, they made modifications on those files as well,
and now we have lot of versions of \*almost\* same thing, and this is hell!
So, I'm using this namespace to group and keep those changes together.

This module may not fit for you, but it's a very simple way to make CRUD schemas on REST,
without prohibit or complicate use of catalyst power, like chains or anything else.

# How it works

CatalystX::Eta do not create any path on you application. This is your job.

Almost all CatalystX::Eta roles need DBIx::Class to work good.

CatalystX::Eta have those packages:

    CatalystX::Eta::Controller::REST
    CatalystX::Eta::Controller::AutoBase
    CatalystX::Eta::Controller::AutoList
    CatalystX::Eta::Controller::AutoObject
    CatalystX::Eta::Controller::AutoResult
    CatalystX::Eta::Controller::CheckRoleForPOST
    CatalystX::Eta::Controller::CheckRoleForPUT
    CatalystX::Eta::Controller::ListAutocomplete
    CatalystX::Eta::Controller::Search
    CatalystX::Eta::Controller::TypesValidation
    CatalystX::Eta::Controller::ParamsAsArray
    CatalystX::Eta::Controller::SimpleCRUD
    CatalystX::Eta::Controller::AssignCollection
    CatalystX::Eta::Test::REST

And now, with a little description:

    CatalystX::Eta::Controller::REST
        - NOT a Moose::ROLE.
        - extends Catalyst::Controller::REST
        - overwrite /end to catch die.

    CatalystX::Eta::Controller::AutoBase
        - requires 'base';
        - load $c->stash->{collection} a $c->model( $self->config->{result} )

    CatalystX::Eta::Controller::AutoList
        - requires 'list_GET';
        - requires 'list_POST';
        - list_GET read lines on $c->stash->{collection} then $self->status_ok
        - list_POST $c->stash->{collection}->execute(...) then $self->status_created

    CatalystX::Eta::Controller::AutoObject
        - May $c->detach('/error_404'), so better you implement this Private Path.
        - requires 'object';
        - $c->stash->{object} = $c->stash->{collection}->search( { "me.id" => $id } )

    CatalystX::Eta::Controller::AutoResult
        - requires 'result_GET';
        - requires 'result_PUT';
        - requires 'result_DELETE';
        - result_GET $self->status_ok a $c->stash->{object}
        - result_PUT $c->stash->{object}->execute(...) and $self->status_accepted
        - result_DELETE $c->stash->{object}->delete and $self->status_no_content

    CatalystX::Eta::Controller::CheckRoleForPOST
        - requires 'list_POST';
        - basically:
            if ( !$c->check_any_user_role( @{ $config->{create_roles} } ) ) {
                $self->status_forbidden( $c, message => "insufficient privileges" );
                $c->detach;
            }

    CatalystX::Eta::Controller::CheckRoleForPUT
        - requires 'result_PUT';
        - that's not so simple as CheckRoleForPOST, because it
          depends on what you have the user_id field on $c->stash->{object}
          and sometimes it is true.

    CatalystX::Eta::Controller::ListAutocomplete
        - requires list_GET
        - return { suggestions => [ value => $row->name, data => $row->id ] } instead of
          the normal response, if $c->req->params->{list_autocompleate} is true.

    CatalystX::Eta::Controller::Search
        - requires 'list_GET';
        - read $self->config->{search_ok} and
          $c->stash->{collection}->search( ... ) if the $c->req->params->{$search_keys} are valid.

    CatalystX::Eta::Controller::TypesValidation
        - add validate_request_params method.
        - validate_request_params uses Moose::Util::TypeConstraints::find_or_parse_type_constraint
          to validate $c->req->params->{...}

    CatalystX::Eta::Controller::ParamsAsArray
        - add params_as_array
        - params_as_array is a litle crazy, see it bellow.

    CatalystX::Eta::Controller::SimpleCRUD
        - just a group of with's.

        with 'CatalystX::Eta::Controller::AutoBase';      # 1
        with 'CatalystX::Eta::Controller::AutoObject';    # 2
        with 'CatalystX::Eta::Controller::AutoResult';    # 3

        with 'CatalystX::Eta::Controller::CheckRoleForPUT';
        with 'CatalystX::Eta::Controller::CheckRoleForPOST';

        with 'CatalystX::Eta::Controller::AutoList';      # 1
        with 'CatalystX::Eta::Controller::Search';        # 2

    CatalystX::Eta::Controller::AssignCollection
        - another group of with's

        with 'CatalystX::Eta::Controller::Search';
        with 'CatalystX::Eta::Controller::AutoBase';
        with 'CatalystX::Eta::Controller::AutoObject';
        with 'CatalystX::Eta::Controller::CheckRoleForPUT';
        with 'CatalystX::Eta::Controller::CheckRoleForPOST';

    CatalystX::Eta::Test::REST
        - extends Stash::REST and use Test::More
        - add a trigger process_response to Stash::REST
        this add a test for each request made with Stash::REST
        is(
            $opt->{res}->code,
            $opt->{conf}->{code},
            $desc . ( exists $opt->{conf}->{name} ? ' - ' . $opt->{conf}->{name} : '' )
        );

\# Depends on...

In order to extends \`CatalystX::Eta::Controller::AutoObject\` you need need \`/error\_404\`  Catalyst Private action defined.

\`CatalystX::Eta::Controller::SimpleCRUD\` and  \`CatalystX::Eta::Controller::AssignCollection\` extends \`CEC::AutoObject\`, so you will need in a way, or in another.

\`CatalystX::Eta::Controller::REST\` extends \`Catalyst::Controller::REST\` and make errors from \`DBIx::Class::Exception\` more 'api friendly' than HTML with '(en) Please come back later\\n...'

All your controllers should extends \`CatalystX::Eta::Controller::REST\`.

\`MyApp::TraitFor::Controller::TypesValidation\` add validate\_request\_params use \`Moose::Util::TypeConstraints::find\_or\_parse\_type\_constraint\` so you can do things like:

        $self->validate_request_params(
            $c,
            extra_days => {
                type     => 'Int',
                required => 0,
            },
            credit_card_id => {
                type     => 'Int',
                required => 0,
            },
        );

on your controllers, and it does the $c->status\_bad\_request or $c->detach for you.

# AUTHOR

Renato CRON <rentocron@cpan.org>

# COPYRIGHT

Copyright 2015- Renato CRON

Thanks to http://eokoe.com

# Disclaimer

I'm using the word "REST" application but it really depends on you implement the truly REST. Catalyst::Controller::REST and
CatalystX::Eta::Controller::REST only implement a JSON/YAML response, but lot of people would call those applications REST.

Please do not use XML response with Catalyst::Controller::REST, because it use Simple::XML transform your data
into something potentially unstable! If you want XML responses, use create it with a DTD.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[CatalystX::CRUD](https://metacpan.org/pod/CatalystX::CRUD)
