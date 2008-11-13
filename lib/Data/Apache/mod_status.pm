package Data::Apache::mod_status;

=head1 NAME

Data::Apache::mod_status - get valuse from Apache mod_status page

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use warnings;
use strict;

our $VERSION = '0.01';

use Moose;
use Moose::Util::TypeConstraints;
use LWP::UserAgent;
use Carp::Clan 'croak';
use IPC::Run3 'run3';
use XML::LibXSLT;
use XML::LibXML;

use Data::Apache::mod_status::2XML;
use Data::Apache::mod_status::Info;
use Data::Apache::mod_status::Workers;

our $TEMPFILE_TEMPLATE = 'mod_status-XXXXXX';


=head1 PROPERTIES

=cut

subtype 'mod_status-Info' 
    => as 'Object'
    => where { $_[0]->isa('Data::Apache::mod_status::Info') };

subtype 'mod_status-Workers'
    => as 'Object'
    => where { $_[0]->isa('Data::Apache::mod_status::Workers') };

subtype 'XML-LibXML-Document'
    => as 'Object'
    => where { $_[0]->isa('XML::LibXML::Document') };


has 'url' => (
    'is'      => 'rw',
    'isa'     => 'Str',
    'default' => 'http://localhost/server-status',
);

has 'mod_status_output_filename' => (
    'is'  => 'rw',
    'isa' => 'Str',
);

has 'xml_dom' => (
    'is'      => 'rw',
    'isa'     => 'XML-LibXML-Document',
);

has 'info' => (
    'is'      => 'rw',
    'isa'     => 'mod_status-Info'
);

has 'workers' => (
    'is'      => 'rw',
    'isa'     => 'mod_status-Workers'
);

=head1 METHODS

=head2 new()

Object constructor.

=cut

=head2 refresh()

Fetches fresh C<mod_status> page and stores xml in C<xml_dom>.

=cut

sub refresh {
    my $self = shift;

    my $mod_status_page = $self->_fetch_mod_status_page;
    
    my $tidy_mod_status_page;
    my @tidy_cmd = (
        'tidy',
        '-w', '6000',
        '-utf8',
        '-asxhtml',
        '-i',
        '-f', '/dev/null',
    );
    run3(\@tidy_cmd, \$mod_status_page, \$tidy_mod_status_page, undef, { 'return_if_system_error' => 1 });    
    die 'execution of tidy failed'
        if (($? >> 8) > 1);
    
    # make the mod_status page to xml transformation
    my $parser = XML::LibXML->new();
    my $xslt   = XML::LibXSLT->new();
    my $stylesheet = $xslt->parse_stylesheet(
        $parser->parse_string(Data::Apache::mod_status::2XML->xslt()),
    );
    my $mod_status_dom = $stylesheet->transform(
        $parser->parse_string($tidy_mod_status_page)
    );    
    $self->xml_dom(
        $parser->parse_string($stylesheet->output_string($mod_status_dom)),
    );
    
    # update object properties
    $self->refresh_from_dom();
    
    # return self to allow chaining
    return $self;
}

sub refresh_from_dom {
    my $self = shift;
    
    my $dom = $self->xml_dom();
    
    # parse info lines
    my $info = Data::Apache::mod_status::Info->new();
    foreach my $info_line ($dom->findnodes('/mod_status/info_lines/line/text()')) {
        $info_line = $info_line->toString;
        
        $info_line =~ m/^Server \s Version: \s (.+)$/xms
            ? $info->server_version($1) :
        $info_line =~ m/^Server \s Built: \s (.+)$/xms
            ? $info->server_build_str($1) :
        $info_line =~ m/^Current \s Time: \s (.+)$/xms
            ? $info->current_time_str($1) :
        $info_line =~ m/^Restart \s Time: \s (.+)$/xms
            ? $info->restart_time_str($1) :
        $info_line =~ m/^Parent \s Server \s Generation: \s (\d+)$/xms
            ? $info->parent_server_generation($1) :
        $info_line =~ m/^Server \s uptime: \s (.+)$/xms
            ? $info->server_uptime_str($1) :
        $info_line =~ m/^Total \s accesses: \s (\d+) \s - \s Total \s Traffic: \s (\d+(?:\.\d+)?\s.+)$/xms
            ? ($info->total_accesses($1), $info->total_traffic_str($2)) :
        $info_line =~ m/^CPU \s Usage: \s (.+)$/xms
            ? $info->cpu_usage_str($1) :
        $info_line =~ m{requests/sec \s - \s .+/second \s - \s .+/request$}xms
            ? 1 :
        $info_line =~ m/^(\d+) \s requests \s currently \s being \s processed, \s (\d+) \s idle \s workers$/xms
            ? ($info->current_requests($1), $info->idle_workers($2))
        : (die 'unknown mod_status info line "', $info_line, '"');
    }
    
    # store new values
    $self->info($info);
    
    my ($workers_tag) = $dom->findnodes('/mod_status/workers');
    $self->workers(
        Data::Apache::mod_status::Workers->new(
            'workers_tag' => $workers_tag,
        )
    );
    
    return $self;
}

sub _fetch_mod_status_page {
    my $self = shift;
    
    my $url = $self->url;
    croak 'set url'
        if not defined $url;
    
    # get mod_status page
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;
    my $response = $ua->get($url);
    die 'failed to fetch "', $url, '" - '.$response->status_line
        if $response->is_error();
    
    # tidy mod_status page to be xhtml document
    return $response->decoded_content;
}

"Zed's Dead, baby";


__END__

=head1 AUTHOR

Jozef Kutej

=cut
