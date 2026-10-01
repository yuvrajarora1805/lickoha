#!/usr/bin/perl

use strict;
use warnings;
use CGI qw ( -utf8 );
use C4::Auth;
use C4::Output;
use C4::Context;

my $query = new CGI;

# Note: We do NOT require a license check here, otherwise we'd loop infinitely.
# We also do not strictly require authentication flags if the system is completely locked out,
# but we do want to use the intranet template system.
my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "admin/license_expired.tt",
        query           => $query,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { parameters => 'parameters_remaining_permissions' },
        debug           => 1,
    }
);

my $reason = $query->param('reason') || 'Invalid license key';

$template->param(
    reason => $reason,
);

output_html_with_http_headers $query, $cookie, $template->output;
