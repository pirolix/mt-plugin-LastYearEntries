package MT::Plugin::OMV::LastYearEntries;
### LastYearEntries
###         Programmed by Piroli YUKARINOMIYA (MagicVox)
###         Open MagicVox.net - http://www.magicvox.net/
###         @see http://www.magicvox.net/archive/2008/09121803/

use strict;
use MT;
use MT::Entry;
use MT::Template::Context;
use MT::Util qw( epoch2ts ts2epoch );

use vars qw( $NAME $VERSION );
$NAME = 'LastYearEntries';
$VERSION = '0.11';

use base qw( MT::Plugin );
my $plugin = __PACKAGE__->new({
    name => $NAME,
    id => $NAME,
    key => $NAME,
    version => $VERSION,
    description => <<PERLDOCHERE,
Get a list of entries that posted last year about this time.
PERLDOCHERE
    author_name => 'Piroli YUKARINOMIYA',
    author_link => 'http://www.magicvox.net/site/profile',
    doc_link => 'http://www.magicvox.net/archive/2008/09121803/',
});
MT->add_plugin( $plugin );



### MTLastYearEntries container tag
MT::Template::Context->add_container_tag( LastYearEntries => \&_hdlr_last_year_entries );
sub _hdlr_last_year_entries {
    my( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash( 'blog' )
        or return '';

    # Get current time with context
    my $entry = $ctx->stash( 'entry' );
    my $current_time = $entry
            ? ts2epoch( $blog, $entry->created_on )
            : time;
    my $tm_centered = ts2epoch( $blog, last_year_ts( epoch2ts( $blog, $current_time )));

    # Load entries
    my $days = $args->{days} || 30;
    my $ts_start  = epoch2ts( $blog, $tm_centered - $days * 24 * 60 * 60 );
    my $ts_end    = epoch2ts( $blog, $tm_centered + $days * 24 * 60 * 60 );
    my %terms = ( blog_id => $blog->id, created_on => [ $ts_start, $ts_end ], status => MT::Entry::RELEASE());
    my %args = ( range => { created_on => 1 });
    my @entries = MT::Entry->load( \%terms, \%args );

    # Sort by distance between authored ts and centered ts
    @entries = sort {
            abs( ts2epoch( $blog, $a->created_on ) - $tm_centered )
                    <=> abs( ts2epoch( $blog, $b->created_on ) - $tm_centered )
    } @entries;
    # and cut off
    my $lastn = $args->{lastn} || $#entries + 1;
    pop @entries while $lastn <= $#entries;

    # Sort by authored_on again
    @entries = defined $args->{sort_order} && $args->{sort_order} eq 'descend'
            ? sort { $b->created_on <=> $a->created_on } @entries
            : sort { $a->created_on <=> $b->created_on } @entries;

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
