package Data::Apache::mod_status::2XML;

=head1 NAME

Data::Apache::mod_status::LinesXSLT - xslt to transform apache mod status page to xml file

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use warnings;
use strict;

our $VERSION = '0.01';

use FindBin '$Bin';
use File::Slurp;

=head1 METHODS

=head2 xslt()

=cut

sub xslt {
    my $class = shift;
    
    # XSLT should be put statically by installer
    my $mod_status_xslt;
    
    # if running tests, developing read the xslt from file located in the root in xslt/ folder
    if (not defined $mod_status_xslt) {
        $mod_status_xslt = read_file($Bin.'/../xslt/mod_status2xml.xslt');
    }
    
    return $mod_status_xslt;
}

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
