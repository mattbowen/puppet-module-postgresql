define postgresql::database($owner="postgres", $ensure=present) {
  $dbexists = "psql -ltA | grep '^$name|'"
  
  $owner_require = $owner ? {
    "postgres" => undef,
    default => Postgresql::User[$owner]
  }

  Exec {
    require => Package["postgresql-client"],
  }

  if $ensure == 'present' {

    exec { "createdb $name":
      command => "createdb -O $owner $name",
      user => "postgres",
      unless => $dbexists,
      require => $owner_require,
    }


  } elsif $ensure == 'absent' {

    exec { "dropdb $name":
      command => "dropdb $name",
      user => "postgres",
      onlyif => $dbexists,
      before => $owner_require,
    }
  }
}
