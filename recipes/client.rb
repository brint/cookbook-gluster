#
# Cookbook Name:: rackops-gluster
# Recipe:: client
#
# Copyright 2013, Rackspace
#
# All rights reserved - Do Not Redistribute
#
package 'glusterfs-client'
#package 'glusterfs-common'
#package 'fuse-utils'

# create client mountpoint
directory node[:gluster][:client][:mount_point] do
  owner 'root'
  group 'root'
  mode 0755
  recursive true
end

unless node[:gluster][:client][:mount_host].empty?
  mount node[:gluster][:server][:mount_point] do
  	device "#{node[:gluster][:client][:mount_host]}:#{node[:gluster][:client][:mount_point]}"
  	fstype "glusterfs"
  	options "rw"
  	action [:mount, :enable]
  end
end
