# == Class: openvpn
#
class openvpn (
  $package_ensure           = 'present',
  $package_name             = $::openvpn::params::package_name,
  $package_list             = $::openvpn::params::package_list,

  $config_dir_path          = $::openvpn::params::config_dir_path,
  $config_dir_purge         = false,
  $config_dir_recurse       = true,
  $config_dir_source        = undef,

  $config_file_path         = $::openvpn::params::config_file_path,
  $config_file_owner        = $::openvpn::params::config_file_owner,
  $config_file_group        = $::openvpn::params::config_file_group,
  $config_file_mode         = $::openvpn::params::config_file_mode,
  $config_file_source       = undef,
  $config_file_string       = undef,
  $config_file_template     = undef,

  $config_file_notify       = $::openvpn::params::config_file_notify,
  $config_file_require      = $::openvpn::params::config_file_require,

  $config_file_hash         = {},
  $config_file_options_hash = {},

  $service_ensure           = 'running',
  $service_name             = $::openvpn::params::service_name,
  $service_enable           = true,

  $easy_rsa_dir_path        = "${::openvpn::params::config_dir_path}/easy-rsa",
  $easy_rsa_file_path       = "${::openvpn::params::config_dir_path}/easy-rsa/vars",
  $easy_rsa_source          = $::openvpn::params::easy_rsa_source,

  $ca_expire                = 3650,
  $key_expire               = 3650,
  $key_size                 = 1024,
  $key_country              = undef,
  $key_province             = undef,
  $key_city                 = undef,
  $key_organization         = $::domain,
  $key_email                = "admin@${::domain}",
  $key_cn                   = '',
  $key_name                 = '',
  $key_ou                   = '',

  $clients_hash             = {},

  $server_port              = 1194,
  $server_proto             = 'udp',
  $server_dev               = 'tun',
  $server_subnet            = undef,
  $server_push              = undef,
  $server_client_to_client  = false,
  $server_client_config_dir = false,
  $server_compression       = true,
  $server_user              = true,
  $server_group             = true,
) inherits ::openvpn::params {
  validate_re($package_ensure, '^(absent|latest|present|purged)$')
  validate_string($package_name)
  if $package_list { validate_array($package_list) }

  validate_absolute_path($config_dir_path)
  validate_bool($config_dir_purge)
  validate_bool($config_dir_recurse)
  if $config_dir_source { validate_string($config_dir_source) }

  validate_absolute_path($config_file_path)
  validate_string($config_file_owner)
  validate_string($config_file_group)
  validate_string($config_file_mode)
  if $config_file_source { validate_string($config_file_source) }
  if $config_file_string { validate_string($config_file_string) }
  if $config_file_template { validate_string($config_file_template) }

  validate_string($config_file_notify)
  validate_string($config_file_require)

  validate_hash($config_file_hash)
  validate_hash($config_file_options_hash)

  validate_re($service_ensure, '^(running|stopped)$')
  validate_string($service_name)
  validate_bool($service_enable)

  $config_file_content = default_content($config_file_string, $config_file_template)

  if $config_file_hash {
    create_resources('openvpn::define', $config_file_hash)
  }

  if $package_ensure == 'absent' {
    $config_dir_ensure  = 'directory'
    $config_file_ensure = 'present'
    $_service_ensure    = 'stopped'
    $_service_enable    = false
  } elsif $package_ensure == 'purged' {
    $config_dir_ensure  = 'absent'
    $config_file_ensure = 'absent'
    $_service_ensure    = 'stopped'
    $_service_enable    = false
  } else {
    $config_dir_ensure  = 'directory'
    $config_file_ensure = 'present'
    $_service_ensure    = $service_ensure
    $_service_enable    = $service_enable
  }

  validate_re($config_dir_ensure, '^(absent|directory)$')
  validate_re($config_file_ensure, '^(absent|present)$')

  if $clients_hash {
    create_resources('openvpn::client', $clients_hash)
  }

  anchor { 'openvpn::begin': } ->
  class { '::openvpn::install': } ->
  class { '::openvpn::config': } ~>
  class { '::openvpn::service': } ->
  anchor { 'openvpn::end': }
}
