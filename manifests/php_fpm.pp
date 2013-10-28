class nginx::php_fpm {
  $sock_file = "/var/run/php5-fpm.sock"

  package {
    "php5-fpm":
      ensure  => installed,
      require => Package['nginx']
  }

  package {
    [ "php5-mysql", "phpmyadmin", "php5-curl" ]:
      ensure  => installed,
      require => Package['php5-fpm'],
      before  => Package['php5-mcrypt'],
  }

  package {
    "php5-mcrypt":
      ensure => installed,
      notify  => Class["nginx::service"]
  }
}
