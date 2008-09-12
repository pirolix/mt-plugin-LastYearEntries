package MT::Plugin::OMV::LastYearEntries;
### LastYearEntries
###         Programmed by Piroli YUKARINOMIYA (MagicVox)
###         Open MagicVox.net - http://www.magicvox.net/

use strict;
use MT;
use MT::Template::Context;
use MT::Util qw( epoch2ts ts2epoch );

use vars qw( $NAME $VERSION );
$NAME = 'LastYearEntries';
$VERSION = '0.01';

use base qw( MT::Plugin );
my $plugin = __PACKAGE__->new({
    name => $NAME,
    id => $NAME,
    key => $NAME,
    version => $VERSION,
    description => <<PERLDOCHERE,
Get a list of entries which posted last year about this time.
PERLDOCHERE
    author_name => 'Piroli YUKARINOMIYA',
    author_link => 'http://www.magicvox.net/site/profile',
    doc_link => 'http://www.magicvox.net/',
});
MT->add_plugin( $plugin );



### MTLastYearEntries container tag
MT::Template::Context->add_container_tag( LastYearEntries => \&_hdlr_last_year_entries );
sub _hdlr_last_year_entries {
    my( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash( 'blog' );

    # Get current time with context
    my $current_time = time;
    my $entry = $ctx->stash( 'entry' );
    $current_time = ts2epoch( $blog, $entry->authored_on )
        if defined $entry;
    my $tm_centered = ts2epoch( $blog, last_year_ts( epoch2ts( $blog, $current_time )));

    # Load entries
    my $days = $args->{days} || 30;
    my $ts_start  = epoch2ts( $blog, $tm_centered - $days * 24 * 60 * 60 );
    my $ts_end    = epoch2ts( $blog, $tm_centered + $days * 24 * 60 * 60 );
    my %terms = ( authored_on => [ $ts_start, $ts_end ]);
    my %args = ( range => { authored_on => 1 });
    my @entries = MT::Entry->load( \%terms, \%args );

    # Sort by distance between authored ts and centered ts
    @entries = sort {
            abs( ts2epoch( $blog, $a->authored_on ) - $tm_centered )
                    <=> abs( ts2epoch( $blog, $b->authored_on ) - $tm_centered )
    } @entries;
    # and cut off
    my $lastn = $args->{lastn} || $#entries + 1;
    pop @entries while $lastn <= $#entries;

    # Sort by authored_on again
    @entries = defined $args->{sort_order} && $args->{sort_order} eq 'descend'
            ? sort { $b->authored_on <=> $a->authored_on } @entries
            : sort { $a->authored_on <=> $b->authored_on } @entries;

    # build
    my $res = '';
    my $i = 0;
    my $builder = $ctx->stash( 'builder' );
    my $tokens = $ctx->stash( 'tokens' );
    foreach my $e ( @entries ) {
        local $ctx->{__stash}{entry} = $e;
        my $out = $builder->build($ctx, $tokens, {
                %$cond,
                EntriesHeader => (!$i),
                EntriesFooter => (!defined $entries[$i+1]),
         });
        return $ctx->error( $builder->errstr ) unless defined $out;
        $res .= $out;         
        $i++;
    }
    return $res;
}

### Get Timestamp of last year
sub last_year_ts {
    my $ts = shift;
    $ts =~ s!^(\d{4})!$1-1!e;
    $ts;
}

1;
__END__
