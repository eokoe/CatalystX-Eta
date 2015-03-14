requires 'perl', '5.008005';

requires 'Moose::Role';
requires 'Stash::REST', 0.06;

requires 'DBIx::Class';

on test => sub {
    requires 'Catalyst::Runtime', '5.90080';

    requires 'Catalyst::Model::DBIC::Schema';

    requires 'Test::More';

    requires 'Catalyst::Plugin::Authentication';
    requires 'Catalyst::Plugin::Authorization::Roles';
    requires 'DBIx::Class::PassphraseColumn';
    requires 'DBIx::Class::TimeStamp';
    requires 'JSON::MaybeXS';

};
