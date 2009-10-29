package Google::Chart::WithData;
use Moose::Role;
use Google::Chart::Data;
use namespace::clean -except => qw(meta);

# guess what, not all Chart types have datasets associated with it.
# so we make this a role

has data => (
    is       => 'ro',
    isa      => 'Google::Chart::Data',
    required => 1,
    lazy_build => 1,
);

has data_class => (
    is         => 'ro',
    isa        => 'ClassName',
    required   => 1,
    lazy_build => 1,
);

has data_traits => (
    is         => 'ro',
    isa        => 'ArrayRef',
    required   => 1,
    lazy_build => 1,
);

has encoding_class => (
    is => 'ro',
    isa => 'Str',
    default => 'Text',
);

around BUILDARGS => sub {
    my ($next, $self, @args) = @_;
    my $args = $next->($self, @args);

    if (my $encoding_class = delete $args->{encoding}) {
        $args->{encoding_class} = $encoding_class;
    }
    return $args;
};

sub BUILD {
    my ($self, $params) = @_;

    my %encoding_params;
    foreach my $key ( grep { /^encoding_(?!class)/ } keys %$params) {
        my $new_key = $key;
        $new_key =~ s/^encoding_//;
        $encoding_params{ $new_key } = $params->{$key};
    }
    $self->data_encoding( $self->encoding_class, %encoding_params );
    return $self;
}

sub _build_data {
    my $self = shift;

    my $traits = $self->data_traits;
    my $class  = $self->data_class;
    if (@$traits > 0) {
        my $meta = Moose::Meta::Class->create_anon_class(
            superclasses => [ $class ],
            roles => $traits,
            cache => 1,
        );
        $class = $meta->name;
    }

    return $class->new();
}

sub _build_data_class { 'Google::Chart::Data' }
sub _build_data_traits { [] }

sub data_encoding {
    my $self = shift;
    my $encoding = shift;
    if (! blessed $encoding) {
        if ($encoding !~ s/^\+//) {
            $encoding = "Google::Chart::Encoding::$encoding";
        }
        if (! Class::MOP::is_class_loaded($encoding)) {
            Class::MOP::load_class($encoding);
        }
        $encoding = $encoding->new(@_);
    }
    $self->data->set_encoding($encoding);
}

around prepare_query => sub {
    my ($next, $self, @args) = @_;
    my @query = $next->( $self, @args );

    push @query, $self->data->prepare_query( $self );
    return @query;
};

sub add_dataset {
    my $self = shift;
    $self->data->add_dataset(@_);
}

1;

__END__

=head1 NAME

Google::Chart::WithData - Role For Charts That Have "Plottable" Data

=head1 SYNOPSIS

    my $chart = Google::Chart->create(...);
    $chart->add_dataset( @args ); # delegates to Google::Chart::Data
                                  # see there for details

=head1 ATTRIBUTES

=head2 data

Google::Chart::Data instance.

=head2 data_class

Class name to use when auto-generating the C<data> object. 
If your chart class needs some extra mangling, you may want to check this 
or C<data_traits>

=head2 data_traits

Role names to be applied to the data object upon creation.
If your chart class needs some extra mangling, you may want to check this 
or C<data_class>

=head2 encoding_class

Name of the Encoding class that will encode your data. See
L<Google::Chart::Encoding::Extended>, L<Google::Chart::Encoding::Simple>, and L<Google::Chart::Encoding::Text>

=head1 METHODS

=head2 BUILDARGS

Hooks in to Google::Chart's BUILDARGS, and allows the following extra
constructor parameters:

    Google::Chart->create(
        Line => (
            encoding => 'Simple', # Data encoding scheme
        )
    );

=head2 add_dataset( @args )

Adds a new dataset. This method is delegated to Google::Chart::Data.
Please see there for details.

=head2 data_encoding( $class [, %args] )

Change the default encoding. This is a convenience function to change the
encoding scheme after you've created the object.

=cut
