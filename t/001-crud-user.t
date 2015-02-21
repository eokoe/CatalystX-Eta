use utf8;
use FindBin qw($Bin);
use lib "$Bin/lib";
use lib "$Bin/../lib";

use Catalyst::Test q(MyApp);

use Test::More;

my $model = MyApp->model('DB');
ok($model, 'model loaded');
eval {
    $model->schema->deploy
};
is($@, '', 'database deployed success');




done_testing;
