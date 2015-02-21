requires 'perl', '5.008005';

requires 'Moose::Role';
requires 'Stash::REST', 0.06;


on test => sub {
    requires 'Catalyst::Runtime', '5.90080';
};
