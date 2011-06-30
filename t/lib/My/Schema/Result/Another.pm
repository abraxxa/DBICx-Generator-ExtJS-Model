package My::Schema::Result::Another;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
__PACKAGE__->table('Another');

__PACKAGE__->add_columns(
    'id' => {
        'data_type'         => 'int',
        'is_auto_increment' => 1,
        'is_foreign_key'    => 0,
        'name'              => 'id',
        'is_nullable'       => 0,
        'size'              => '10'
    },
    'num' => {
        'is_foreign_key'    => 0,
        'name'              => 'num',
        '2'                 => undef,
        'size'              => '10',
        'is_auto_increment' => 0,
        'data_type'         => 'numeric',
        'is_nullable'       => 1
    },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many( 'get_Basic', 'My::Schema::Result::Basic',
    'another_id' );

1;
