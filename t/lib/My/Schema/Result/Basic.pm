package My::Schema::Result::Basic;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
__PACKAGE__->table('Basic');

__PACKAGE__->add_columns(
    'id' => {
        'data_type'         => 'int',
        'is_auto_increment' => 1,
        'is_foreign_key'    => 0,
        'name'              => 'id',
        'is_nullable'       => 0,
        'size'              => '10'
    },
    'title' => {
        'data_type'         => 'varchar',
        'is_auto_increment' => 0,
        'default_value'     => 'hello',
        'is_foreign_key'    => 0,
        'name'              => 'title',
        'is_nullable'       => 0,
        'size'              => '100'
    },
    'description' => {
        'data_type'         => 'text',
        'is_auto_increment' => 0,
        'is_foreign_key'    => 0,
        'name'              => 'description',
        'is_nullable'       => 1,
        'size'              => '0'
    },
    'email' => {
        'data_type'         => 'varchar',
        'is_auto_increment' => 0,
        'is_foreign_key'    => 0,
        'name'              => 'email',
        'is_nullable'       => 1,
        'size'              => '500'
    },
    'explicitnulldef' => {
        'data_type'         => 'varchar',
        'is_auto_increment' => 0,
        'default_value'     => undef,
        'is_foreign_key'    => 0,
        'name'              => 'explicitnulldef',
        'is_nullable'       => 1,
        'size'              => '0'
    },
    'explicitemptystring' => {
        'data_type'         => 'varchar',
        'is_auto_increment' => 0,
        'default_value'     => '',
        'is_foreign_key'    => 0,
        'name'              => 'explicitemptystring',
        'is_nullable'       => 1,
        'size'              => '0'
    },
    'emptytagdef' => {
        'data_type'         => 'varchar',
        'is_auto_increment' => 0,
        'is_foreign_key'    => 0,
        'name'              => 'emptytagdef',
        'is_nullable'       => 1,
        'size'              => '0'
    },
    'another_id' => {
        'data_type'         => 'int',
        'is_auto_increment' => 0,
        'default_value'     => 2,
        'is_foreign_key'    => 1,
        'name'              => 'another_id',
        'is_nullable'       => 1,
        'size'              => '10'
    },
    'timest' => {
        'data_type'         => 'timestamp',
        'is_auto_increment' => 0,
        'is_foreign_key'    => 0,
        'name'              => 'timest',
        'is_nullable'       => 1,
        'size'              => '0'
    },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to( 'another_id', 'My::Schema::Result::Another' );

1;
