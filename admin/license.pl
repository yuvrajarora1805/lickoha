#!/usr/bin/perl

use strict;
use warnings;
use CGI qw ( -utf8 );
use C4::Auth;
use C4::Output;
use C4::Context;
use Koha::Config::SysPrefs;

my $query = new CGI;
my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "admin/license.tt",
        query           => $query,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { parameters => 'parameters_remaining_permissions' },
        debug           => 1,
    }
);

my $op = $query->param('op') || '';

if ( $op eq 'save' ) {
    my $new_key = $query->param('license_key');
    if ( defined $new_key ) {
        my $syspref = Koha::Config::SysPrefs->find('InoutLicenseKey');
        if ($syspref) {
            $syspref->set({ value => $new_key })->store;
        } else {
            Koha::Config::SysPref->new({
                variable => 'InoutLicenseKey',
                value    => $new_key,
                explanation => 'License key for AMC',
                type => 'Free'
            })->store;
        }
        $template->param( message => "License key saved successfully." );
    }
}

# Fetch current status
my $key = C4::Context->preference("InoutLicenseKey") || "";
my $status = "Not Installed";
my $reason = "";
my $plan = "";
my $expiry = "";

if ($key) {
    my $url = "https://inout.omvky.com/api/verify?key=$key&mac=&domain=localhost&product=koha";
    my $content = `curl -s -k "$url" 2>/dev/null`;
    
    if ($content) {
        if ($content =~ /"status"\s*:\s*"success"/) {
            $status = "Active";
            if ($content =~ /"plan"\s*:\s*"([^"]+)"/) { $plan = $1; }
            if ($content =~ /"expiry_date"\s*:\s*"([^"]+)"/) { $expiry = $1; }
        } else {
            $status = "Inactive";
            if ($content =~ /"message"\s*:\s*"([^"]+)"/) { $reason = $1; }
        }
    } else {
        $status = "Server Offline";
        $reason = "Could not connect to license server.";
    }
}

$template->param(
    license_key => $key,
    license_status => $status,
    license_reason => $reason,
    license_plan => $plan,
    license_expiry => $expiry,
);

output_html_with_http_headers $query, $cookie, $template->output;
