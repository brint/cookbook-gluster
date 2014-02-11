#
# Cookbook Name:: rackops-gluster
# Recipe:: server
#
# Copyright 2013, Rackspace
#
# All rights reserved - Do Not Redistribute
#

# Append self to list of volume_nodes
node.set[:gluster][:server][:volume_nodes] = Array.new(node[:gluster][:server][:volume_nodes]).push(node[:network][:interfaces][:eth1][:addresses].map {|i| i.first if i.last['family'].eql?('inet') }.compact.first)

package 'xfsprogs'
package 'glusterfs-server'
package 'vnstat'

block_device = node[:gluster][:server][:block_device]
mount_point = node[:gluster][:server][:mount_point]
volume = node[:gluster][:server][:volume_name]
replica_cnt = node[:gluster][:server][:volume_nodes].count
node_cnt = replica_cnt
peer_cnt = replica_cnt - 1
auth_clients = node[:gluster][:server][:auth_clients].join(" ")
is_last_node = node[:gluster][:server][:is_last_node]
volume_nodes = node[:gluster][:server][:volume_nodes]

directory mount_point do
  owner 'root'
  group 'root'
  mode 0755
  recursive true
end

if File.exists?(block_device)
  mount mount_point do
    device block_device
    fstype 'xfs'
    options 'rw'
    action [:mount, :enable]
  end
  execute 'mkfs.xfs' do
    command "mkfs.xfs -i size=512 #{block_device}"
    not_if { system("blkid -s TYPE -o value #{block_device}") }
  end
else
  log "Block device #{block_device} does not exist."
end

if is_last_node
  # peer up the nodes
  node[:gluster][:server][:volume_nodes].each do |n|
    execute "Peer probe #{n}:#{mount_point}" do
      command "gluster peer probe #{n}:#{mount_point}"
      retries 1
      retry_delay 1
      not_if "gluster peer status | grep '^Hostname: #{n}:{mount_point}$'"
    end
  end

  # create the volume if it doesn't exist
  execute 'Create GlusterFS Volume' do
    command "gluster volume create #{volume} replica #{replica_cnt} #{volume_nodes.join(":#{mount_point} ")}"
    retries 1
    retry_delay 5
    not_if "gluster volume info | egrep '^Volume Name: #{volume}:#{mount_point}$'"
    only_if "echo \"#{peer_cnt} == `gluster peer status | egrep \"^Number of Peers: \" | awk '{print $4}'`\" | bc -l"
  end

  # !!! CHANGES TO AUTHENTICATION REQUIRES MANUAL STOP/START OF VOLUME FOR NOW !!!
  execute 'Configure GlusterFS auth.allow' do
    command "gluster volume set #{volume}:#{mount_point} auth.allow #{auth_clients}"
    retries 1
    retry_delay 5
    not_if "gluster volume info #{volume}:#{mount_point} | egrep \"^auth.allow: #{auth_clients}\""
  end

  execute "Start GlusterFS volume #{volume}" do
    command "gluster volume start #{volume}:#{mount_point}"
    retries 1
    retry_delay 5
    not_if "gluster volume info #{volume}:#{mount_point}| egrep '^Status: Started'"
  end
end
