Section: IOS configuration
username admin privilege 15 password Password123
hostname ${hostname}
interface GigabitEthernet2
ip address dhcp
ip nat inside
no shut
exit
%{ if test_client_ip != "" ~}
ip nat inside source static tcp ${test_client_ip} 22 interface GigabitEthernet1 2222
%{ endif ~}
%{ for key, conn in public_conns ~}
%{ if conn.pre_shared_key != "" ~}
crypto ikev2 keyring ${conn.remote_gateway_ip}-${gateway[conn.gw_name].public_ip}
peer ${conn.remote_gateway_ip}-${gateway[conn.gw_name].public_ip}
address ${gateway[conn.gw_name].public_ip}
identity address ${gateway[conn.gw_name].public_ip}
pre-shared-key ${conn.pre_shared_key}
exit
exit
%{ endif ~}
crypto ikev2 proposal avx-s2c
encryption aes-cbc-256
integrity sha256
group 14
exit
crypto ikev2 policy 200
proposal avx-s2c
exit
crypto ikev2 profile ${conn.remote_gateway_ip}-${gateway[conn.gw_name].public_ip}
match identity remote address ${gateway[conn.gw_name].public_ip} 255.255.255.255
identity local address ${conn.remote_gateway_ip}
authentication remote pre-share
authentication local pre-share
keyring local ${conn.remote_gateway_ip}-${gateway[conn.gw_name].public_ip}
lifetime 28800
dpd 10 3 periodic
exit
crypto ipsec transform-set ${conn.remote_gateway_ip}-${gateway[conn.gw_name].public_ip} esp-aes 256 esp-sha256-hmac
mode tunnel
exit
crypto ipsec df-bit clear
crypto ipsec profile ${conn.remote_gateway_ip}-${gateway[conn.gw_name].public_ip}
set security-association lifetime seconds 3600
set transform-set ${conn.remote_gateway_ip}-${gateway[conn.gw_name].public_ip}
set pfs group14
set ikev2-profile ${conn.remote_gateway_ip}-${gateway[conn.gw_name].public_ip}
exit
interface Tunnel ${index(pub_conn_keys, key) + 1}
ip address ${split("/", split(",", conn.remote_tunnel_cidr)[0])[0]} 255.255.255.252
ip mtu 1436
ip tcp adjust-mss 1387
tunnel source GigabitEthernet1
tunnel mode ipsec ipv4
tunnel destination ${gateway[conn.gw_name].public_ip}
tunnel protection ipsec profile ${conn.remote_gateway_ip}-${gateway[conn.gw_name].public_ip}
ip virtual-reassembly
exit
router bgp ${conn.bgp_remote_as_num}
bgp log-neighbor-changes
neighbor ${split("/", split(",", conn.local_tunnel_cidr)[0])[0]} remote-as ${conn.bgp_local_as_num}
neighbor ${split("/", split(",", conn.local_tunnel_cidr)[0])[0]} timers 10 30 30
address-family ipv4
redistribute connected
%{ if length(adv_prefixes) != 0 ~}
redistribute static
%{ endif ~}
neighbor ${split("/", split(",", conn.local_tunnel_cidr)[0])[0]} activate
neighbor ${split("/", split(",", conn.local_tunnel_cidr)[0])[0]} soft-reconfiguration inbound
maximum-paths 4
exit-address-family
exit
%{ if length(split(",", conn.local_tunnel_cidr)) > 1 ~}
%{ if conn.pre_shared_key != "" ~}
crypto ikev2 keyring ${conn.remote_gateway_ip}-${gateway[conn.gw_name].ha_public_ip}
peer ${conn.remote_gateway_ip}-${gateway[conn.gw_name].ha_public_ip}
address ${gateway[conn.gw_name].ha_public_ip}
identity address ${gateway[conn.gw_name].ha_public_ip}
pre-shared-key ${conn.pre_shared_key}
exit
exit
%{ endif ~}
crypto ikev2 profile ${conn.remote_gateway_ip}-${gateway[conn.gw_name].ha_public_ip}
match identity remote address ${gateway[conn.gw_name].ha_public_ip} 255.255.255.255
identity local address ${conn.remote_gateway_ip}
authentication remote pre-share
authentication local pre-share
keyring local ${conn.remote_gateway_ip}-${gateway[conn.gw_name].ha_public_ip}
lifetime 28800
dpd 10 3 periodic
exit
crypto ipsec transform-set ${conn.remote_gateway_ip}-${gateway[conn.gw_name].ha_public_ip} esp-aes 256 esp-sha256-hmac
mode tunnel
exit
crypto ipsec profile ${conn.remote_gateway_ip}-${gateway[conn.gw_name].ha_public_ip}
set security-association lifetime seconds 3600
set transform-set ${conn.remote_gateway_ip}-${gateway[conn.gw_name].ha_public_ip}
set pfs group14
set ikev2-profile ${conn.remote_gateway_ip}-${gateway[conn.gw_name].ha_public_ip}
exit
interface Tunnel ${index(pub_conn_keys, key) +1}0
ip address ${split("/", split(",", conn.remote_tunnel_cidr)[1])[0]} 255.255.255.252
ip mtu 1436
ip tcp adjust-mss 1387
tunnel source GigabitEthernet1
tunnel mode ipsec ipv4
tunnel destination ${gateway[conn.gw_name].ha_public_ip}
tunnel protection ipsec profile ${conn.remote_gateway_ip}-${gateway[conn.gw_name].ha_public_ip}
ip virtual-reassembly
exit
router bgp ${conn.bgp_remote_as_num}
neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} remote-as ${conn.bgp_local_as_num}
neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} timers 10 30 30
address-family ipv4
neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} activate
neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} soft-reconfiguration inbound
exit-address-family
exit
%{ endif ~}
%{ endfor ~}
%{ for key, conn in private_conns ~}
%{ if conn.pre_shared_key != "" ~}
crypto ikev2 keyring ${conn.remote_gateway_ip}-${gateway[conn.gw_name].private_ip}
peer ${conn.remote_gateway_ip}-${gateway[conn.gw_name].private_ip}
address ${gateway[conn.gw_name].private_ip}
identity address ${gateway[conn.gw_name].private_ip}
pre-shared-key ${conn.pre_shared_key}
exit
exit
%{ endif ~}
crypto ikev2 proposal avx-s2c
encryption aes-cbc-256
integrity sha256
group 14
exit
crypto ikev2 policy 200
proposal avx-s2c
exit
crypto ikev2 profile ${conn.remote_gateway_ip}-${gateway[conn.gw_name].private_ip}
match identity remote address ${gateway[conn.gw_name].private_ip} 255.255.255.255
identity local address ${conn.remote_gateway_ip}
authentication remote pre-share
authentication local pre-share
keyring local ${conn.remote_gateway_ip}-${gateway[conn.gw_name].private_ip}
lifetime 28800
dpd 10 3 periodic
exit
crypto ipsec transform-set ${conn.remote_gateway_ip}-${gateway[conn.gw_name].private_ip} esp-aes 256 esp-sha256-hmac
mode tunnel
exit
crypto ipsec df-bit clear
crypto ipsec profile ${conn.remote_gateway_ip}-${gateway[conn.gw_name].private_ip}
set security-association lifetime seconds 3600
set transform-set ${conn.remote_gateway_ip}-${gateway[conn.gw_name].private_ip}
set pfs group14
set ikev2-profile ${conn.remote_gateway_ip}-${gateway[conn.gw_name].private_ip}
exit
interface Tunnel ${index(priv_conn_keys, key) + length(pub_conn_keys) + 1}
ip address ${split("/", split(",", conn.remote_tunnel_cidr)[0])[0]} 255.255.255.252
ip mtu 1436
ip tcp adjust-mss 1387
tunnel source GigabitEthernet1
tunnel mode ipsec ipv4
tunnel destination ${gateway[conn.gw_name].private_ip}
tunnel protection ipsec profile ${conn.remote_gateway_ip}-${gateway[conn.gw_name].private_ip}
ip virtual-reassembly
exit
router bgp ${conn.bgp_remote_as_num}
bgp log-neighbor-changes
neighbor ${split("/", split(",", conn.local_tunnel_cidr)[0])[0]} remote-as ${conn.bgp_local_as_num}
neighbor ${split("/", split(",", conn.local_tunnel_cidr)[0])[0]} timers 10 30 30
address-family ipv4
redistribute connected
%{ if length(adv_prefixes) != 0 ~}
redistribute static
%{ endif ~}
neighbor ${split("/", split(",", conn.local_tunnel_cidr)[0])[0]} activate
neighbor ${split("/", split(",", conn.local_tunnel_cidr)[0])[0]} soft-reconfiguration inbound
maximum-paths 4
exit-address-family
exit
%{ if length(split(",", conn.local_tunnel_cidr)) > 1 ~}
%{ if conn.pre_shared_key != "" ~}
crypto ikev2 keyring ${conn.remote_gateway_ip}-${gateway[conn.gw_name].ha_private_ip}
peer ${conn.remote_gateway_ip}-${gateway[conn.gw_name].ha_private_ip}
address ${gateway[conn.gw_name].ha_private_ip}
identity address ${gateway[conn.gw_name].ha_private_ip}
pre-shared-key ${conn.pre_shared_key}
exit
exit
%{ endif ~}
crypto ikev2 profile ${conn.remote_gateway_ip}-${gateway[conn.gw_name].ha_private_ip}
match identity remote address ${gateway[conn.gw_name].ha_private_ip} 255.255.255.255
identity local address ${conn.remote_gateway_ip}
authentication remote pre-share
authentication local pre-share
keyring local ${conn.remote_gateway_ip}-${gateway[conn.gw_name].ha_private_ip}
lifetime 28800
dpd 10 3 periodic
exit
crypto ipsec transform-set ${conn.remote_gateway_ip}-${gateway[conn.gw_name].ha_private_ip} esp-aes 256 esp-sha256-hmac
mode tunnel
exit
crypto ipsec profile ${conn.remote_gateway_ip}-${gateway[conn.gw_name].ha_private_ip}
set security-association lifetime seconds 3600
set transform-set ${conn.remote_gateway_ip}-${gateway[conn.gw_name].ha_private_ip}
set pfs group14
set ikev2-profile ${conn.remote_gateway_ip}-${gateway[conn.gw_name].ha_private_ip}
exit
interface Tunnel ${index(priv_conn_keys, key) + length(pub_conn_keys) + 1}0
ip address ${split("/", split(",", conn.remote_tunnel_cidr)[1])[0]} 255.255.255.252
ip mtu 1436
ip tcp adjust-mss 1387
tunnel source GigabitEthernet1
tunnel mode ipsec ipv4
tunnel destination ${gateway[conn.gw_name].ha_private_ip}
tunnel protection ipsec profile ${conn.remote_gateway_ip}-${gateway[conn.gw_name].ha_private_ip}
ip virtual-reassembly
exit
router bgp ${conn.bgp_remote_as_num}
neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} remote-as ${conn.bgp_local_as_num}
neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} timers 10 30 30
address-family ipv4
neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} activate
neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} soft-reconfiguration inbound
exit-address-family
exit
%{ endif ~}
%{ endfor ~}
%{ for index, prefix in adv_prefixes ~}
ip route ${split("/", prefix)[0]} ${cidrnetmask(prefix)} Null0
%{ endfor ~}
end
wr mem
