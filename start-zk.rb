#!/usr/bin/env ruby

# this file is a shim that starts up a zookeeper process, called by the Rakefile's start_* tasks

JVM_FLAGS = %W[-server -Xmx256m -XX:+UseConcMarkSweepGC]
ZOO_MAIN  = 'org.apache.zookeeper.server.quorum.QuorumPeerMain'

srv_num = ENV['ZOO_SRV_NUM']


zoo_root    = ENV.fetch('ZOO_ROOT')
zoo_log_dir = ENV.fetch('ZOO_LOG_DIR')
zoo_cfg     = ENV.fetch('ZOO_CFG')
zoo_cfg_dir = File.dirname(zoo_cfg)

classpath = ([zoo_cfg_dir] + Dir["#{zoo_root}/lib/*.jar", "#{zoo_root}/*.jar"]).map { |d| File.expand_path(d) }.uniq.join(':')

cmdline = %W[
  java
  -Dzookeeper.serverCnxnFactory=org.apache.zookeeper.server.NettyServerCnxnFactory
  -Dzookeeper.log.dir=#{zoo_log_dir}
  -cp #{classpath}
]
cmdline += JVM_FLAGS

cmdline += [ZOO_MAIN, zoo_cfg]

$stderr.puts "cmdline: #{cmdline.join(' ')}"

exec(*cmdline)

