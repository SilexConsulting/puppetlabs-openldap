# == Class: openldap::client::debian
#
# === Parameters
#
# [*basedn*]
#   Specifies the default base DN to use when performing ldap
#   operations.  The base must be specified as a Distinguished
#   Name in LDAP format.
#
# [*uri*]
#   The URI of an LDAP server to which the LDAP library should
#   connect.
#
# [*tls_enabled*]
#   Enable Transport Layer Security support.
#
# [*tls_cert_path*]
#   Specifies the file that contains certificates for all of the
#   Certificate Authorities the client will recognize.
#   Ignored unless tls_enabled == true.
#
# [*tls_cacert*]
#   The source file that should be served from Puppet. This file
#   must exist under the '${module_path}/openldap/files/' directory.
#   Ignored unless tls_enabled == true.
#
# [*tls_reqcert*]
#   Specifies what checks to perform on server certificates in a
#   TLS session, if any. See man ldap.conf 5.
#   Ignored unless tls_enabled == true.
#
# [*timelimit*]
#   Specifies  a  time limit (in seconds) to use when performing
#   searches.  The number should be a non-negative integer.
#
# [*network_timeout*]
#   Specifies the network timeout (in seconds) in case of no activity.
#
# === Variables
#
# === Examples
#  
#  class { 'openldap::client::debian':
#    basedn      => 'dc=puppetlabs,dc=com',
#    uri         => 'ldap://ldap.puppetlabs.com',
#    tls_enabled => true,
#  }
#
# === Authors
#
#  Kelsey Hightower kelsey@puppetlabs.com
#
# === Copyright
#
# Copyright 2012 Puppet Labs, Inc
#
class openldap::client::debian (
  $basedn,
  $uri,
  $tls_enabled     = false,
  $tls_cacert_path = "/etc/ssl/certs/openldap_cacert.pem",
  $tls_cacert      = "openldap_cacert.pem",
  $tls_reqcert     = "demand",
  $timelimit       = 15,
  $network_timeout = 30,
) {

  $package_list = [
    'ldap-utils',
    'libpam-ldapd',
    'nslcd',
  ]

  package { $package_list:
    ensure => latest,
  }

  if $tls_enabled {
    file { "$tls_cacert_path":
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => "puppet:///modules/openldap/$tls_cacert",
    }
  }

  file { '/etc/ldap/ldap.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("openldap/ldap.conf.erb"),
  }

  file { '/etc/nsswitch.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/openldap/nsswitch.conf',
  }

  #########################################################
  # Configure nslcd - local LDAP name service daemon
  #
  # libpam-ldapd requires that the nslcd daemon is running
  # in order for PAM to authenticate using LDAP.
  #
  service { 'nslcd':
    ensure    => running,
    require   => Package['nslcd'],
    subscribe => File['/etc/nslcd.conf'],
  }

  file { '/etc/nslcd.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("openldap/nslcd.conf.erb"),
    require => [
      Package['nslcd'],
      Service['nslcd'],
    ]
  }

  #########################################################
  # Configure PAM to use LDAP
  #
  file { '/etc/pam.d/common-session': 
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => "puppet:///modules/openldap/common-session",
    require => Package['libpam-ldapd'],
  }

  file { '/etc/pam.d/common-password':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => "puppet:///modules/openldap/common-password",
    require => Package['libpam-ldapd'],
  }

  file { '/etc/pam.d/common-session-noninteractive':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => "puppet:///modules/openldap/common-session-noninteractive",
    require => Package['libpam-ldapd'],
  }
  
  file { '/etc/pam.d/common-auth':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => "puppet:///modules/openldap/common-auth",
    require => Package['libpam-ldapd'],
  }

  file { '/etc/pam.d/common-account':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => "puppet:///modules/openldap/common-account",
    require => Package['libpam-ldapd'],
  }
}

