
# install nginx
# ensure it runs
# enable mod_rewrite
# enable mod_php5

## CONFIG

class nginx {
  $nginx_sites = "/etc/nginx/sites"
  $nginx_includes = "/etc/nginx/site-includes"
  $nginx_mods = "/etc/nginx/mods"
  $nginx_conf = "/etc/nginx/conf.d"
  $nginx_root = "/var/www"


  # setup packages
  package {
    "nginx": ensure => installed ;
    #"nginx-mpm-prefork": ensure => installed ;
  }

  include nginx::service
}

class nginx::service {
  # setup service
  service { "nginx":
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    require => Package["nginx"],
  }

  # Notify this when nginx needs a reload. This is only needed when
  # sites are added or removed, since a full restart then would be
  # a waste of time. When the module-config changes, a force-reload is
  # needed.
  exec { "reload-nginx":
    command => "/usr/sbin/service nginx reload",
    refreshonly => true,
  }

  exec { "force-reload-nginx":
    command => "/usr/sbin/service nginx force-reload",
    refreshonly => true,
  }
}

define nginx::vhost (
  $domain = "",
  $documentroot = "",
  $domainalias = "",
  $includes = []
) {
  include nginx

  if $domain == "" {
    $vhost_domain = $name
    } else {
      $vhost_domain = $domain
    }

  if $domainalias == "" {
    $vhost_alias = "www.${vhost_domain}"
    } else {
      $vhost_alias = $domainalias
    }

  if $documentroot == "" {
    $vhost_root = "${nginx_root}/${name}"
    } else {
      $vhost_root = $documentroot
    }

      file { "${nginx::nginx_sites}-available/${vhost_domain}":
        ensure => 'present',
        content => template("nginx/vhost.erb"),
        require => Package['nginx'],
        ## notify => Exec["enable-${vhost_domain}-vhost"],
        }
}


# Define an nginx site. Place all site configs into
# /etc/nginx/sites-available and en-/disable them with this type.
#
# You can add a custom require (string) if the site depends on packages
# that aren't part of the default nginx package. Because of the
# package dependencies, nginx will automagically be included.
define nginx::site ( $ensure = 'present') {
  include nginx

  case $ensure {
    'present' : {
      exec { "nginx::site::enable $name":
        unless => "/bin/readlink -e ${nginx::nginx_sites}-enabled/$name",
        command => "ln -s ${nginx::nginx_sites}-available/$name ${nginx::nginx_sites}-enabled/$name",
        notify => Exec["reload-nginx"],
        require => File["${nginx::nginx_sites}-available/$name"],
      }
    }

    'absent' : {
      exec { "nginx::site::disable $name":
        onlyif => "/bin/readlink -e ${nginx::nginx_sites}-enabled/$name",
        notify => Exec["reload-nginx"],
        command => "rm ${nginx::nginx_sites}-enabled/$name",
        require => File["${nginx::nginx_sites}-available/$name"],
      }
    }
    default: { err ( "Unknown ensure value: '$ensure'" ) }
  }
}


