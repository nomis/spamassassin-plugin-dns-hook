# Copyright 2025  Simon Arlott
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Mail::SpamAssassin::Plugin::DnsHook;

use strict;
use warnings;

use Mail::SpamAssassin::AsyncLoop;
use Mail::SpamAssassin::DnsResolver;
use Mail::SpamAssassin::Logger;
use Mail::SpamAssassin::Plugin;

our @ISA = qw(Mail::SpamAssassin::Plugin);

my $dns_hook_config = ();

{
	no warnings "redefine";

	sub rewrite_domain {
		my ($domain) = @_;
		my $conf = $dns_hook_config;

		if ($conf->{spamhaus_dqs_key} ne "") {
			if ($domain =~ /^(.+)\.(dbl|dwl|sbl|sbl-xbl|swl|xbl|zen)\.spamhaus\.org$/) {
				$domain = join(".", $1, $conf->{spamhaus_dqs_key}, $2, "dq.spamhaus.net");
			}
		}

		return $domain;
	}

	my $bgsend = \&Mail::SpamAssassin::DnsResolver::bgsend;

	*Mail::SpamAssassin::DnsResolver::bgsend = sub {
		my ($self, $domain, $type, $class, $cb) = @_;

		$domain = rewrite_domain($domain);

		return $bgsend->($self, $domain, $type, $class, $cb);
	};

	my $bgsend_and_start_lookup = \&Mail::SpamAssassin::AsyncLoop::bgsend_and_start_lookup;

	*Mail::SpamAssassin::AsyncLoop::bgsend_and_start_lookup = sub {
		my ($self, $domain, $type, $class, $ent, $cb, %options) = @_;

		$domain = rewrite_domain($domain);

		return $bgsend_and_start_lookup->($self, $domain, $type, $class, $ent, $cb, %options);
	}
}

sub new {
	my ($class, $mailsa) = @_;
	$class = ref($class) || $class;
	my $self = $class->SUPER::new( $mailsa );
	bless ($self, $class);

	$self->{mailsa} = $mailsa;
	$self->set_config($mailsa->{conf});

	return $self;
}

sub set_config {
	my($self, $conf) = @_;
	my @cmds;

	push (@cmds, {
		setting => "spamhaus_dqs_key",
		default => "",
		type => $Mail::SpamAssassin::Conf::CONF_TYPE_STRING
	});

	$conf->{parser}->register_commands(\@cmds);
}

sub finish_parsing_end {
	my ($self, $opts) = @_;

	$dns_hook_config = $opts->{conf};
}
