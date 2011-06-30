use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Differences;
use lib 't/lib';
use DBICx::Generator::ExtJS::Model;
use My::Schema;

my $schema = My::Schema->connect;

my $generator = DBICx::Generator::ExtJS::Model->new(
    schema    => $schema,
    json_args => {
        space_after => 1,
        indent      => 1,
    },
    extjs_args => { extend => 'MyApp.data.Model', },
);

my $extjs_model_for_another;
lives_ok { $extjs_model_for_another = $generator->extjs_model('Another') }
"generation of 'Another' successful";
eq_or_diff(
    $extjs_model_for_another,
    [   'Another',
        {   'extend'       => 'MyApp.data.Model',
            'associations' => [
                {   'foreignKey'     => 'id',
                    'model'          => 'Basic',
                    'type'           => 'hasMany',
                    'associationKey' => 'get_Basic',
                    'primaryKey'     => 'another_id',
                }
            ],
            'fields' => [
                {   'data_type' => 'int',
                    'name'      => 'id',
                },
                {   'data_type' => 'int',
                    'name'      => 'num',
                },
            ],
            'idProperty' => 'id',
        }
    ],
    "'Another' model ok"
);

my $extjs_models;
lives_ok { $extjs_models = $generator->extjs_models; }
'generation successful';

eq_or_diff(
    $extjs_models,
    {   'Another' => [
            'Another',
            {   'extend'       => 'MyApp.data.Model',
                'associations' => [
                    {   'foreignKey'     => 'id',
                        'model'          => 'Basic',
                        'type'           => 'hasMany',
                        'associationKey' => 'get_Basic',
                        'primaryKey'     => 'another_id',
                    }
                ],
                'fields' => [
                    {   'data_type' => 'int',
                        'name'      => 'id',
                    },
                    {   'data_type' => 'int',
                        'name'      => 'num',
                    },
                ],
                'idProperty' => 'id',
            },
        ],
        'Basic' => [
            'Basic',
            {   'extend'       => 'MyApp.data.Model',
                'associations' => [
                    {   'foreignKey'     => 'another_id',
                        'model'          => 'Another',
                        'associationKey' => 'another_id',
                        'type'           => 'belongsTo',
                        'primaryKey'     => 'id',
                    }
                ],
                'fields' => [
                    {   'data_type' => 'int',
                        'name'      => 'id',
                    },
                    {   'data_type'     => 'string',
                        'default_value' => 'hello',
                        'name'          => 'title',
                    },
                    {   'data_type' => 'string',
                        'name'      => 'description',
                    },
                    {   'data_type' => 'string',
                        'name'      => 'email',
                    },
                    {   'data_type'     => 'string',
                        'default_value' => undef,
                        'name'          => 'explicitnulldef',
                    },
                    {   'data_type'     => 'string',
                        'default_value' => '',
                        'name'          => 'explicitemptystring',
                    },
                    {   'data_type' => 'string',
                        'name'      => 'emptytagdef',
                    },
                    {   'data_type'     => 'int',
                        'default_value' => 2,
                        'name'          => 'another_id',
                    },
                    {   'data_type' => 'date',
                        'name'      => 'timest',
                    },
                ],
                'idProperty' => 'id',
            },
        ],
    },
    "extjs_models output ok"
);

done_testing;
