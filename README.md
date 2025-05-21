# Overview
Hook into SpamAssassin DNS lookups to modify the hostnames used for Spamhaus
lookups to use a DQS key.

# Usage 
```
loadplugin Mail::SpamAssassin::Plugin::DnsHook /usr/local/lib/spamassassin-plugin-dns-hook/DnsHook.pm

spamhaus_dqs_key **************************
```
