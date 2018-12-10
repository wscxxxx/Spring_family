#!/usr/bin/env ruby
#encoding=utf-8
# NOTE
# 服务器HA配置脚本
# role：可选项为master或slave。
# IP地址说明：server1和server2为实际两台服务器的IP，对应的域名为server1.com和server2.com。
# haserver为指定的虚拟IP，虚拟IP不能被其他机器占用，需要和实际服务器IP在同一网段。对应的域名为haserver.com。
# NOTE:本脚本可以重复使用。可以在脚本最后的一部分注释掉相应的方法，以跳过不需重复执行的操作。

require 'fileutils'
require 'socket'
DEPLOY_PATH = "/home/ewhine/deploy/faye"
OLD_DEPLOY_PATH = "#{DEPLOY_PATH}.old"
DEAMON = "mx_faye"


Options = {
  enabled:  true,
  keepalived_interface: "eth0",
  virtual_router_id: "31",
  data_store: "/data/storage",
  server1:  "192.168.100.221",
  server2:  "192.168.100.222",
  haserver: "192.168.100.220",
  local_epel_repo: true,
  haserver_soto: ""
}

def put_usage
  usage = <<EOF
使用root账户运行本脚本。格式：ruby ./ha_config.rb {master|slave} 。
执行本脚本之前请先设置网络、放开防火墙的限制，并将Options[:enabled]设置为true。
使用 master|slave 选项指定该服务器初始角色为主机或备机。可选项为master或slave。
请先在master上执行，再在slave上执行。
EOF
  puts usage
end

def local_ip
  local_ips = Socket.ip_address_list.map {|addrinfo| addrinfo.ip_address}
  servers_ips = [ Options[:server1], Options[:server2] ]
  (local_ips & servers_ips ).first
end

def another_ip
  local_ips = Socket.ip_address_list.map {|addrinfo| addrinfo.ip_address}
  servers_ips = [ Options[:server1], Options[:server2] ]
  (servers_ips - local_ips ).first
end

def test_before_config server
  db = system "mysql -uroot -pVM5LVDn8fe -h#{server} -e 'show master status;' > /dev/null"
  redis = system "redis-cli -h #{server} info > /dev/null"
  if !db
    puts "无法登陆#{server}的mysql服务器。请确定防火墙开启3306端口、mysql能够监听外网地址，并且其他IP使用root用户登陆。"
    puts "安装中止。"
    exit 1
  end
  if !redis
    puts "无法连接到#{server}的redis服务器。请确定防火墙开启6379端口、redis能监听外网地址。"
    puts "安装中止。"
    exit 2
  end
end

#20170627
def config_repo
  system "mv /etc/yum.repos.d /etc/yum.repos.d.bak"
  system "mkdir /etc/yum.repos.d"
  system "mv /home/ewhine/ha_config/ha.repo /etc/yum.repos.d/"
  system "yum clean all"
end
def restore_repo
  system "rm -rf /etc/yum.repos.d"
  system "mv /etc/yum.repos.d.bak /etc/yum.repos.d"
end



#20170627

def install_ha_pkg
  puts "开始安装必要软件包。安装过程中请保持联网。"
#20170627 注释
#  if !Options[:local_epel_repo]
#    if !system("yum install -y epel-release")
#      puts  "添加epel源失败，请检查yum配置或网络配置。"
#      exit 1
#    end
#
#    if !system("yum install -y centos-release-gluster")
#      puts  "添加glusterfs源失败，请检查网络配置。"
#      exit 1
#    end
#  end

#20170627
  if !system("yum install -y keepalived glusterfs glusterfs-server")
    puts  "安装glusterfs、keepalived失败，请检查yum配置或网络配置。"
    exit 1
  end
end

def set_hosts server1, server2, haserver, role
  puts "设置hosts。"
  another_server = another_ip()
#   another_server = case role
#                    when "master"
#                      server2
#                    when "slave"
#                      server1
#                    end
  if system("grep server1.com /etc/hosts >> /dev/null")
    cmd1 = 'sed -i "s/[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}\([ \t]\+server1.com\)/' + server1 + '\1/g" /etc/hosts'
    cmd2 = 'sed -i "s/[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}\([ \t]\+server2.com\)/' + server2 + '\1/g" /etc/hosts'
    cmd3 = 'sed -i "s/[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}\([ \t]\+haserver.com\)/' + haserver + '\1/g" /etc/hosts'
    cmd5 = 'sed -i "s/[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}\([ \t]\+anotherserver.com\)/' + another_server + '\1/g" /etc/hosts'
    puts "更新host项。"

    `#{cmd1}`
    `#{cmd2}`
    `#{cmd3}`
    `#{cmd5}`
  else
    puts "追加host项。"
    append_hosts = <<HOSTS
#==========minxing ha hosts start===========
#{server1}          server1.com
#{server2}          server2.com
#{haserver}         haserver.com
#{another_server}   anotherserver.com
#==========minxing ha hosts end===========
HOSTS
    `echo '#{append_hosts}' >> /etc/hosts`
  end
end

def generate_keepalived_conf haserver, role, keepalived_interface, virtual_router_id, haserver_soto
  puts "生成keepalived.conf。"
  FileUtils.mkdir_p "/etc/keepalived"

  case role
  when "master"
    priority_vi_1 = "250"
  when "slave"
    priority_vi_1 = "150"
  end

  keepalived_conf = <<KEEPALIVEDCONF
global_defs {
   notification_email {
     ewhine@localhost
   }
   notification_email_from Dehui Network
   smtp_server localhost
   smtp_connect_timeout 30
   router_id LVS_DEVEL
}
vrrp_instance VI_1 {
    state BACKUP
    interface #{keepalived_interface}
    virtual_router_id #{virtual_router_id}
    priority #{priority_vi_1}
    advert_int 60
    nopreempt
    notify_master /etc/keepalived/notify_master.sh
    notify_backup /etc/keepalived/notify_backup.sh
    advert_int 60
    authentication {
      auth_type PASS
      auth_pass 1111
    }
    virtual_ipaddress {
      #{haserver}
      #{haserver_soto}
    }
}
KEEPALIVEDCONF

    #   keepalived_conf = keepalived_conf_orig.gsub('vip_vi_1', haserver).gsub('priority_vi_1', priority_vi_1)

    File.open('/etc/keepalived/keepalived.conf', 'w') do |f|
      f.write(keepalived_conf)
    end

    puts "生成notify_master.sh。"
    notify_master_script = <<NOTIFYMASTER
#!/bin/bash
echo [`date`]"作为master启动" >> /home/ewhine/var/log/keepalived.log
/etc/init.d/mx_sidekiq stop
/etc/init.d/mx_sidekiq start
/opt/ewhine/bin/redis-cli slaveof NO ONE
NOTIFYMASTER

    File.open('/etc/keepalived/notify_master.sh', 'w') do |f|
      f.write(notify_master_script)
    end
    `chmod +x /etc/keepalived/notify_master.sh`

    puts "生成notify_backup.sh。"
    notify_backup_script = <<NOTIFYBACKUP
#!/bin/bash
echo [`date`]"作为backup启动" >> /home/ewhine/var/log/keepalived.log
/opt/ewhine/bin/redis-cli  slaveof anotherserver.com 6379
du /home/ewhine/deploy/ewhine_NB/efiles  >> /dev/null &
echo "flush_all" | /opt/ewhine/bin/nc localhost 11211 -c
NOTIFYBACKUP
    File.open('/etc/keepalived/notify_backup.sh', 'w') do |f|
      f.write(notify_backup_script)
    end
    `chmod +x /etc/keepalived/notify_backup.sh`

#     `ln -s /etc/rc3.d/S70keepalived /etc/init.d/keepalived`

    `chkconfig keepalived off`
    system 'sed -i "s/chkconfig:   - 86 14/chkconfig:   - 30 70/g" /etc/init.d/keepalived'
    `chkconfig keepalived on`

end


def configure_mysql_replication server1, server2, role
  puts "设置server_id。"
  server_id = case role
              when "master"
                "10"
              when "slave"
                "20"
              end

  FileUtils.cp "my.cnf", "/etc/my.cnf"

  sed_cmd = 'sed -i "s/\(server-id[ \t]*=[ \t]*\)[0-9]\+/\1' + server_id + '/g" /etc/my.cnf'
  `#{sed_cmd}`
  `service mx_mysqld restart`

  puts "注册同步用户。"

  # do sth.
  `mysql -uroot -pVM5LVDn8fe -e "use mysql;update user set Host = '%' where Host = 'localhost';grant replication slave on *.* to 'slaveuser'@'%' identified by 'minxing_slaver_123';flush privileges;"`

  puts "设置mysql同步。"
  if role == "slave"
    test_before_config server1
    test_before_config server2

    `mysql -hserver1.com -uroot -pVM5LVDn8fe -e "stop slave; reset slave;"`
    `mysql -hserver2.com -uroot -pVM5LVDn8fe -e "stop slave; reset slave;"`
    `mysqldump -uroot -pVM5LVDn8fe --add-drop-table --add-locks esns_production | mysql -hanotherserver.com -uroot -pVM5LVDn8fe esns_production`
    set_mysql "server1.com", "server2.com"
    set_mysql "server2.com", "server1.com"

    system "mysql -hserver1.com -uroot -pVM5LVDn8fe -e \"grant all on esns_production.* to esns@'%' identified by 'minxing123';flush privileges;\""
    system "mysql -hserver2.com -uroot -pVM5LVDn8fe -e \"grant all on esns_production.* to esns@'%' identified by 'minxing123';flush privileges;\""
  else
    # do nothing.
  end
end

def configure_redis server1, server2, role
  system 'sed -i "s/bind\(.*\)/bind 0.0.0.0/g" /opt/ewhine/etc/redis/6379.conf'
  system 'su ewhine -c "/etc/init.d/mx_redis restart"'
  if role == "slave"
    system "redis-cli  slaveof anotherserver.com 6379"
  end
end

def set_mysql origin, replica
  puts "配置从#{origin}到#{replica}的复制"
  cmd_orig = <<MYSQLREPLICA
mysql -hreplica -uroot -pVM5LVDn8fe -e "stop slave; change master to  master_host='origin', master_user='slaveuser', master_password='minxing_slaver_123', master_log_file='logfile', master_log_pos=logpos;start slave;"
MYSQLREPLICA

  mysql_cmd = 'mysql -h' + origin + ' -uroot -pVM5LVDn8fe -e  "show master status\G"'
  res = `#{mysql_cmd}`
  logfile = (/File: (mariadb-bin.[0-9]+)/ =~ res; $1)
  logpos = (/Position: ([0-9]+)/ =~ res; $1)

  cmd = cmd_orig.gsub("logfile", logfile).gsub("logpos", logpos.to_s).gsub("replica", replica).gsub("origin", origin)
  `#{cmd}`
  # TODO:检查slave状态是否成功启动
end

def configure_glusterfs_client role, server1, server2, data_store="/data/export"
  # 生成glusterfs客户端配置文件
  glst_data_store = "#{data_store}/glusterfs"
  FileUtils.mkdir_p glst_data_store unless File.exists? glst_data_store
  FileUtils.chown("ewhine", "ewhine", data_store)
  FileUtils.chown("ewhine", "ewhine", glst_data_store)
  FileUtils.mkdir "/home/ewhine/efiles" unless File.exists? "/home/ewhine/efiles"
  FileUtils.chown("ewhine", "ewhine", "/home/ewhine/efiles")
  system "mv  /home/ewhine/deploy/ewhine_NB/efiles/* /home/ewhine/efiles/" if role == "master"

#   begin
#     FileUtils.mv "/home/ewhine/deploy/ewhine_NB/efiles", "/home/ewhine/"
#   rescue Errno::EEXIST
#     #do nothing.
#   end
#   FileUtils.mkdir_p "/home/ewhine/deploy/ewhine_NB/efiles"

  puts "生成glusterfs服务端配置文件"
  glusterfsd_vol = <<GLUSTERFSD
volume posix
type storage/posix
option directory #{glst_data_store}
end-volume

volume locks
type features/locks
subvolumes posix
end-volume

volume brick
type performance/io-threads
option thread-count 32
subvolumes locks
end-volume

volume server
type protocol/server
option transport-type tcp
option auth.addr.brick.allow *
subvolumes brick
end-volume
GLUSTERFSD
  File.open("/etc/glusterfs/glusterfsd.vol", "w") do |f|
    f.write(glusterfsd_vol)
  end

  `/etc/init.d/glusterfsd restart`

  puts "生成glusterfs客户端配置文件"
  glusterfs_vol = <<GLUSTERFS
volume server1
type protocol/client
option transport-type tcp
option remote-host server1.com
option remote-subvolume brick
end-volume

volume server2
type protocol/client
option transport-type tcp
option remote-host server2.com
option remote-subvolume brick
end-volume

volume replicate
type cluster/replicate
subvolumes server1 server2
end-volume

volume writebehind
type performance/write-behind
option cache-size 1024KB
option flush-behind on
subvolumes replicate
end-volume

volume cache
type performance/io-cache
option cache-size 1024MB
subvolumes writebehind
end-volume
GLUSTERFS

  File.open("/etc/glusterfs/glusterfs.vol", "w") do |f|
    f.write(glusterfs_vol)
  end

  `sed -i '3,$s/NORMAL/ERROR/g;3,$s/#//g'  /etc/sysconfig/glusterd`
  `sed -i '3,$s/NORMAL/ERROR/g;3,$s/#//g'  /etc/sysconfig/glusterfsd`

  if system "grep glusterfs /etc/rc.local >> /dev/null"
    # already in rc.local. do nothing.
  else
    `chkconfig mx_rainbows off`
    `chkconfig mx_sidekiq off`
    `chkconfig mx_monit off`

    start_cmd = <<STARTCMD
glusterfs -f /etc/glusterfs/glusterfs.vol /home/ewhine/deploy/ewhine_NB/efiles/
/etc/init.d/mx_nginx start
su ewhine -c "/etc/init.d/mx_monit start"
STARTCMD
    `echo '#{start_cmd}' >> /etc/rc.local`
  end

  `chkconfig glusterd off`
  `chkconfig mx_nginx off`
  `chkconfig glusterfsd on`
end

def replace_initd_scripts
  `cp -f initds/* /etc/init.d/`
  `cp -f minxing_ctl.rb /home/ewhine/minxing_ctl.rb`
  `su ewhine -c "service mx_monit restart"`
end

def set_mxpp_load_balance
  mxpp_store = "/home/ewhine/deploy/ewhine_NB/efiles/mxpp"
  system "mkdir -p #{mxpp_store}"
  system "chown -R ewhine:ewhine #{mxpp_store}"
  `cp -f config/config_flavor.json /home/ewhine/deploy/mxpp/`
end

#20170904

def set_faye_balance
#  puts "停止faye服务"
  system "/etc/init.d/mx_faye  stop"
  `cp -f config/config.json /home/ewhine/deploy/faye/`

  system "echo \"ha_production\" >> /home/ewhine/deploy/faye/version.txt "
  system "/etc/init.d/mx_faye restart"

end



def set_mx_search
  #vim /home/ewhine/deploy/ewhine_search/conf/server.properties
  #index.directory=indexs，替换为#{data_store}/mx_search
  #server2上的monit移除监控脚本、移除mx_search启动项、移除initd脚本
  #TODO: 只在server2上做
  if local_ip() == Options[:server2]
    system 'sed -i "s/\(.*search.*\)/#\1/g" /opt/ewhine/etc/monitrc'
    `/etc/init.d/mx_monit restart`
    `chkconfig mx_search off`
    `/etc/init.d/mx_search stop`
  end

  properties = <<PROPERTIES
min.thread=20
max.thread=50
max.ideltime=2000
index.directory=#{Options[:data_store]}/indexs
server.port=8888
redis.host=haserver.com
redis.port=6379
PROPERTIES
  
  File.open('/home/ewhine/deploy/ewhine_search/conf/server.properties', 'w') do |f|
    f.write(properties)
  end
  FileUtils.chown("ewhine", "ewhine", '/home/ewhine/deploy/ewhine_search/conf/server.properties')

  system 'sed -i "s/search_service_url: \(.*\)/search_service_url: http:\/\/server1.com:8888\/search/g" /home/ewhine/deploy/ewhine_NB/current/config/application.yml'

  if File.exists? "/home/ewhine/deploy/ewhine_NB/current/config/application_oem.yml"
    system 'sed -i "s/search_service_url: \(.*\)/search_service_url: http:\/\/server1.com:8888\/search/g" /home/ewhine/deploy/ewhine_NB/current/config/application_oem.yml'
  end

  `/etc/init.d/mx_search restart` if local_ip() == Options[:server1]
  
end

# 重启glusterfs-server keepalived，重启nginx，挂载虚拟分区
def restart_services_and_mount role
  `service glusterfsd restart` 
  `umount /home/ewhine/deploy/ewhine_NB/efiles >> /dev/null`
  `service keepalived restart`
  `glusterfs -f /etc/glusterfs/glusterfs.vol /home/ewhine/deploy/ewhine_NB/efiles/`
  `cp config/server.cfg /home/ewhine/deploy/blackhole_zwei/server.cfg`
  `chown ewhine:ewhine /home/ewhine/deploy/blackhole_zwei/server.cfg`
  `mv /home/ewhine/efiles/* /home/ewhine/deploy/ewhine_NB/efiles/` if role == "master"
end

# 将rails项目中的mysql/redis/sidekiq配置文件的host修改为虚拟IP并重启rails和sidekiq
def change_rails_config
  `chown ewhine:ewhine -R config/*.yml config/*.rb`
  system 'sed -i "s/localhost\|127.0.0.1/haserver.com/g" /home/ewhine/deploy/ewhine_NB/current/config/application.yml'
  system 'sed -i "s/localhost\|127.0.0.1/haserver.com/g" /home/ewhine/deploy/ewhine_NB/current/config/redis.yml'

  if File.exists? "/home/ewhine/deploy/ewhine_NB/current/config/application_oem.yml"
    system 'sed -i "s/localhost\|127.0.0.1/haserver.com/g" /home/ewhine/deploy/ewhine_NB/current/config/application_oem.yml'
  end
  system %q{sed -i 's/VERSION[ \t]*=[ \t]*"\(.*\)"/VERSION = "\1_ha_temp"/g' /home/ewhine/deploy/ewhine_NB/current/lib/version.rb}
  `touch /home/ewhine/deploy/blackhole_zwei/init_data.tmp`
  `chown ewhine:ewhine /home/ewhine/deploy/blackhole_zwei/init_data.tmp`

  `cp config/database.yml /home/ewhine/deploy/ewhine_NB/current/config/database.yml`
  `cp config/cache_store.yml /home/ewhine/deploy/ewhine_NB/current/config/cache_store.yml`
  `cp config/production.rb /home/ewhine/deploy/ewhine_NB/current/config/environments/production.rb`
  `cp config/site.conf /opt/ewhine/nginx/conf/ewhine/site.conf`
  `/etc/init.d/mx_nginx restart > /dev/null 2>&1`
  `su ewhine -c "/home/ewhine/minxing_ctl.rb restart_services"`
end


case
when ["--help", "-h"].include?(ARGV.first)
  put_usage

when ARGV.first == "change_rails_config"
  change_rails_config
when ARGV.first != "master" && ARGV.first != "slave" && ARGV != "change_rails_config"
  puts "您没有指定当前主机的初始角色。初始角色是master或slave。"
  put_usage
when Options[:enabled] != true
  puts "当前Options[:enabled]不为true，无法执行配置。请打开此脚本文件，并配置Options选项中的IP。确定选项无误后，将其中的Options[:enabled]字段设置为true，重新执行本脚本。"
else

  role = ARGV.first
  server1 = Options[:server1]
  server2 = Options[:server2]
  haserver = Options[:haserver]
  haserver_soto = Options[:haserver_soto]
  keepalived_interface = Options[:keepalived_interface]
  data_store = Options[:data_store]
  virtual_router_id = Options[:virtual_router_id]
  #   role, server1, server2, haserver = ARGV


  confirm = <<CONFIRM
请确认以下参数：
haserver.com:\t#{haserver}
server1.com:\t#{server1}
server2.com:\t#{server2}
按y继续，其他选项退出
CONFIRM
  puts confirm
  if "y" != STDIN.gets.chomp
    puts "已中止"
    exit
  end
  puts "开始配置"
  
  #配置本地ha_yum源
  config_repo

  # 安装keepalived、glusterfs等必要软件包
  install_ha_pkg

  #还原yum配置
  restore_repo

  # 设置host表
  set_hosts server1, server2, haserver, role

  # 生成keepalived配置文件
  generate_keepalived_conf haserver, role, keepalived_interface, virtual_router_id, haserver_soto

  # 若当前为从机，则从主机同步redis的数据
  configure_redis server1, server2, role

  # 修改mysql的server_id, 配置主从复制
  configure_mysql_replication server1, server2, role

  # 替换initd脚本、monitrc、minxing_ctl并重启monit
  replace_initd_scripts



  # 设置mxpp的负载均衡
  set_mxpp_load_balance

  # 配置mx_search
  set_mx_search

  # 升级faye为ha
  set_faye_balance

  # 配置glusterfs配置文件
  configure_glusterfs_client role, server1, server2, data_store

  # 将rails项目中的mysql/redis/sidekiq配置文件的host修改为虚拟IP
  change_rails_config

  # 重启glusterfs keepalived,挂载虚拟分区
  restart_services_and_mount role

  puts "配置完毕。请您重新启动服务器。"
end
system "/bin/bash cover_iptables.sh"
system "/opt/ewhine/nginx/sbin/nginx -s reload"
