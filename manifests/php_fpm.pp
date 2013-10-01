class nginx::php_fpm {
  $sock_file = "/var/run/php5-fpm.sock"

  package {
    "php5-fpm":   ensure => installed;
    "php5-mysql": ensure => installed;
  }
}
