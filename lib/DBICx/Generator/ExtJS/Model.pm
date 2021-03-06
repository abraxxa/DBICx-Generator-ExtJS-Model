package DBICx::Generator::ExtJS::Model;

#ABSTRACT: ExtJS model producer

=head1 NAME

DBICx::Generator::ExtJS::Model - ExtJS model producer

=head1 SYNOPSIS

    use DBICx::Generator::ExtJS::Model;
    use lib 't/lib';
    use My::Schema;

    my $schema = My::Schema->connect;

    my $generator = DBICx::Generator::ExtJS::Model->new(
        schema  => $schema,
        appname => 'MyApp',
        # this are the default args passed to JSON::DWIW->new
        json_args => {
            bare_keys => 1,
            pretty    => 1,
        },
        extjs_args => {
            extend => 'MyApp.data.Model',
        },
    );
    
    my $extjs_model_for_foo = $generator->extjs_model('Foo');

    my @extjs_models = $generator->extjs_models;

    $generator->extjs_model_to_file( 'Foo', '/my/dir/' );

    $generator->extjs_models_to_file( '/my/dir/' );

=head1 DESCRIPTION

Creates ExtJS model classes.

At the moment only version 4 of the ExtJS framework is supported.

=head1 SEE ALSO

F<http://docs.sencha.com/ext-js/4-0/#/api/Ext.data.Model> for
ExtJS model documentation.

=cut

use Moose;
use JSON::DWIW;
use Path::Class;
use Fcntl qw( O_CREAT O_WRONLY O_EXCL );
use namespace::autoclean;

has 'schema' => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
    required => 1,
);

has 'appname' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has '_json' => (
    is         => 'ro',
    isa        => 'JSON::DWIW',
    lazy_build => 1,
);

sub _build__json {
    my $self = shift;

    return JSON::DWIW->new( $self->json_args );
}

has 'json_args' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        {   bare_keys => 1,
            pretty    => 1,
        };
    },
);

has 'extjs_args' => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => ['Hash'],
    handles => {
        all_extjs_args => 'elements',
        has_extjs_arg  => 'count',
    },
);

my %translate = (

    #
    # MySQL types
    #
    bigint     => 'int',
    double     => 'float',
    decimal    => 'float',
    float      => 'float',
    int        => 'int',
    integer    => 'int',
    mediumint  => 'int',
    smallint   => 'int',
    tinyint    => 'int',
    char       => 'string',
    varchar    => 'string',
    tinyblob   => 'auto',
    blob       => 'auto',
    mediumblob => 'auto',
    longblob   => 'auto',
    tinytext   => 'string',
    text       => 'string',
    longtext   => 'string',
    mediumtext => 'string',
    enum       => 'string',
    set        => 'string',
    date       => 'date',
    datetime   => 'date',
    time       => 'date',
    timestamp  => 'date',
    year       => 'date',

    #
    # PostgreSQL types
    #
    numeric             => 'float',
    'double precision'  => 'float',
    serial              => 'int',
    bigserial           => 'int',
    money               => 'float',
    character           => 'string',
    'character varying' => 'string',
    bytea               => 'auto',
    interval            => 'float',
    boolean             => 'boolean',
    point               => 'float',
    line                => 'float',
    lseg                => 'float',
    box                 => 'float',
    path                => 'float',
    polygon             => 'float',
    circle              => 'float',
    cidr                => 'string',
    inet                => 'string',
    macaddr             => 'string',
    bit                 => 'int',
    'bit varying'       => 'int',

    #
    # Oracle types
    #
    number   => 'float',
    varchar2 => 'string',
    long     => 'float',
);

=over 4

=item extjs_model_name

This method returns the ExtJS model name for a table and can be overridden
in a subclass.

=cut

sub extjs_model_name {
    my ( $self, $tablename ) = @_;
    $tablename = $tablename =~ m/^(?:\w+::)* (\w+)$/x ? $1 : $tablename;
    return ucfirst($tablename);
}

=item extjs_model

This method returns an arrayref containing the parameters that can be
serialized to JSON and then passed to Ext.define for one
DBIx::Class::ResultSource.

=cut

sub extjs_model {
    my ( $self, $rsrcname ) = @_;
    my $schema = $self->schema;

    my $rsrc      = $schema->source($rsrcname);
    my $extjsname = $self->extjs_model_name($rsrcname);

    #print "resultsource: $rsrcname -> $extjsname\n";
    my $columns_info = $rsrc->columns_info;
    my @fields;
    foreach my $colname ( $rsrc->columns ) {

        #print "\tcolumn: $colname\n";
        my $field_params = { name => $colname };
        my $column_info = $columns_info->{$colname};

        # views might not have column infos
        if ( not %$column_info ) {
            $field_params->{data_type} = 'auto';
        }
        else {
            my $data_type = lc( $column_info->{data_type} );
            if ( exists $translate{$data_type} ) {
                my $extjs_data_type = $translate{$data_type};

                # determine if a numeric column is an int or a really a float
                if ( $extjs_data_type eq 'float' ) {
                    $extjs_data_type = 'int'
                        if exists $column_info->{size}
                            && $column_info->{size} !~ /,/;
                }
                $field_params->{data_type} = $extjs_data_type;
            }

            $field_params->{default_value} = $column_info->{default_value}
                if exists $column_info->{default_value};
        }
        push @fields, $field_params;
    }

    my @pk = $rsrc->primary_columns;

    my $model = {
        extend => 'Ext.data.Model',
        fields => \@fields,
    };
    $model->{idProperty} = $pk[0]
        if @pk == 1;

    my @assocs;
    foreach my $relname ( $rsrc->relationships ) {

        # print "\trel: $relname\n";
        my $relinfo = $rsrc->relationship_info($relname);

        # use Data::Dumper;
        # print Dumper($relinfo);
        print
            "\t\tskipping because multi-cond rels aren't supported by ExtJS 4\n"
            if keys %{ $relinfo->{cond} } > 1;

        my $attrs = $relinfo->{attrs};

        #$VAR1 = {
        #    'cond' => {
        #        'foreign.id_maintenance' => 'self.fk_maintenance'
        #    },
        #    'source' => 'NAC::Model::DBIC::Table::Maintenance',
        #    'attrs' => {
        #        'is_foreign_key_constraint' => 1,
        #        'fk_columns' => {
        #            'fk_maintenance' => 1
        #        },
        #        'undef_on_null_fk' => 1,
        #        'accessor' => 'single'
        #    },
        #    'class' => 'NAC::Model::DBIC::Table::Maintenance'
        #};
        my ($rel_col) = keys %{ $relinfo->{cond} };
        my $our_col = $relinfo->{cond}->{$rel_col};
        $rel_col =~ s/^foreign\.//;
        $our_col =~ s/^self\.//;
        my $extjs_rel = {
            associationKey => $relname,

            # class instead of source?
            model      => $self->extjs_model_name( $relinfo->{source} ),
            primaryKey => $rel_col,
            foreignKey => $our_col,
        };

        # belongsTo
        if ($attrs->{is_foreign_key_constraint}
            && (   $attrs->{accessor} eq 'single'
                || $attrs->{accessor} eq 'filter' )
            )
        {
            $extjs_rel->{type} = 'belongsTo';
        }

        # HasOne
        elsif ( $attrs->{accessor} eq 'single' ) {
            $extjs_rel->{type} = 'hasOne';
        }

        #$VAR1 = {
        #    'cond' => {
        #        'foreign.fk_fw_request' => 'self.id_fw_request'
        #    },
        #    'source' => 'NAC::Model::DBIC::Table::FW_Rules',
        #    'attrs' => {
        #        'order_by' => 'rule_index',
        #        'join_type' => 'LEFT',
        #        'cascade_copy' => 1,
        #        'cascade_delete' => 0,
        #        'accessor' => 'multi'
        #    },
        #    'class' => 'NAC::Model::DBIC::Table::FW_Rules'
        #};
        elsif ( $attrs->{accessor} eq 'multi' ) {
            $extjs_rel->{type} = 'hasMany';
        }
        push @assocs, $extjs_rel;
    }
    $model->{associations} = \@assocs
        if @assocs;

    # override any generated config properties
    if ( $self->extjs_args ) {
        my %foo = ( %$model, $self->all_extjs_args );
        $model = \%foo;
    }

    return [ $extjsname, $model ];
}

=item extjs_models

This method returns the generated ExtJS model classes as hashref indexed by
their ExtJS names.

=cut

sub extjs_models {
    my $self = shift;

    my $schema = $self->schema;

    my %output;
    foreach my $rsrcname ( $schema->sources ) {
        my $extjs_model = $self->extjs_model($rsrcname);

        $output{ $extjs_model->[0] } = $extjs_model;
    }

    return \%output;
}

=item extjs_model_to_file

This method takes a single DBIx::Class::ResultSource name and a directory name
and outputs the generated ExtJS model class to a file according to ExtJS
naming standards.
An error is thrown if the directory doesn't exist or if the file already
exists.

=cut

sub extjs_model_to_file {
    my ( $self, $rsrcname, $dirname ) = @_;

    my $dir = Path::Class::Dir->new($dirname);
    $dir->open or die "directory doesn't exist";

    my ( $extjs_model_name, $extjs_model_code ) =
        @{ $self->extjs_model($rsrcname) };

    my $json =
        'Ext.define('
        . $self->_json->to_json(
        $self->appname . '.model.' . $extjs_model_name )
        . ', '
        . $self->_json->to_json($extjs_model_code) . ');';

    my $file = $dir->file("$extjs_model_name.js");
    my $fh   = $file->open( O_CREAT | O_WRONLY | O_EXCL )
        or die "$file already exists";

    $fh->write($json);
}

=item extjs_models_to_file

This method takes a directory name and outputs the generated ExtJS model
classes to a file per model according to ExtJS naming standards.

=cut

sub extjs_models_to_file {
    my ( $self, $dirname ) = @_;

    my $schema = $self->schema;

    $self->extjs_model_to_file( $_, $dirname ) for $schema->sources;
}

=back

1;
