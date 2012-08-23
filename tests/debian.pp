class { 'openldap::client':
  basedn      => 'dc=puppetlabs,dc=com',
  uri         => 'ldap://ldap.puppetlabs.com',
  tls_enabled => true,
}
