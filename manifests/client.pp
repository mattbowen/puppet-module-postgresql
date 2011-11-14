class postgresql::client {
  package { "postgresql-client":
    ensure => present,
  }
  package { "libpq-dev":
    ensure => present,
  }
}
