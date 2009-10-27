
package Google::Chart::Type::XY;
use Moose;
use namespace::clean -except => qw(meta);

sub _build_type { 'lxy' };

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Google::Chart::Type::XY - Google::Chart XY Line Type

In charts of this type, each drawn line is defined by a pair of 
data sets, one of X coordinates and one for Y coordinates. See
the API documentation at

    http://code.google.com/apis/chart/types.html#line_charts

for details.

=cut
