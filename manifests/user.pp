define postgresql::user($ensure=present,
                        $password="",
                        $superuser=false,
                        $createdb=false,
                        $createrole=false) {
  $username = $title
  $userexists = "psql --tuples-only -c 'SELECT rolname FROM pg_catalog.pg_roles;' | grep '^ ${username}$'"
  $user_owns_zero_databases = "psql --tuples-only --no-align -c \"SELECT COUNT(*) FROM pg_catalog.pg_database JOIN pg_authid ON pg_catalog.pg_database.datdba = pg_authid.oid WHERE rolname = '${username}';\" | grep -e '^0$'"

  if $ensure == 'present' {

    exec { "createuser $username":
      command => "createuser --no-superuser --no-createdb --no-createrole ${username}",
      user    => "postgres",
      unless  => $userexists,
      require => Class["postgresql::server"],
    }

    if $password {
      exec { "set password ${username} ${password}":
        command => "psql -c \"ALTER USER ${username} WITH UNENCRYPTED PASSWORD '${password}';\"",
        user => "postgres",
        require => Exec["createuser $username"],
      }
    }
    
    $superuser_option  = $superuser  ? {true => "SUPSERUSER", false => "NOSUPERUSER"}
    $createdb_option   = $createdb   ? {true => "CREATEDB",   false => "NOCREATEDB"}
    $createrole_option = $createrole ? {true => "CREATEROLE", false => "NOCREATEROLE"}

    exec { "set superuser ${username}":
      command => "psql -c \"ALTER USER ${username} WITH ${superuser_option};\"",
      user => "postgres",
      require => Exec["createuser $username"],
    }

    exec { "set createdb ${username}":
      command => "psql -c \"ALTER USER ${username} WITH ${createdb_option};\"",
      user => "postgres",
      require => Exec["createuser $username"],
    }

    exec { "set createrole ${username}":
      command => "psql -c \"ALTER USER ${username} WITH ${createrole_option};\"",
      user => "postgres",
      require => Exec["createuser $username"],
    }

  } elsif $ensure == 'absent' {

    exec { "dropuser $username":
      command => "dropuser ${username}",
      user => "postgres",
      onlyif => "$userexists && $user_owns_zero_databases",
    }

  }
}

define postgresql::user::privilege($privilege,
                                   $object,
                                   $user,
                                   $ensure=present,
                                   $with_grant_option=false) {

    if $with_grant_option {
        $grantopt = "WITH GRANT OPTION"
    } else {
        $grantopt = ""
    }

    # The simplest way to "ensure" the given privilege state is to first revoke, then grant
    exec {"revoke $privilege on $object from $user":
        command => "psql -c \"REVOKE $privilege ON $object FROM $user;\"",
        user => "postgres",
        require => Postgresql::User[$user]
    }

    if ensure == 'present' {
        exec {"grant $privilege on $object to $user":
            command => "psql -c \"GRANT $privilege ON $object TO $user $grantopt;\"",
            user => "postgres",
            require => Exec["revoke $privilege on $object from $user"]
        }
    }

}
