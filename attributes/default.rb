default[:gluster][:client][:mount_host] = ''
default[:gluster][:client][:mount_point] = '/mnt/gluster-volume'

default[:gluster][:server][:mount_point] = '/data/gv0/brick1'
default[:gluster][:server][:block_device] = '/dev/xvde1'
default[:gluster][:server][:volume_name] = 'GlusterFS'

default[:gluster][:server][:auth_clients] = []
default[:gluster][:server][:volume_nodes] = []
# Interface to use for cluster communication/IP configuration
default[:gluster][:server][:interface] = 'eth1'
default[:gluster][:server][:is_last_node] = false
