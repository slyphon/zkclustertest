ZOO_ROOT    = ENV['ZOO_ROOT'] || '/opt/case_sense/zookeeper/zookeeper-3.3.3'
NUM_SERVERS = (ENV['NUM_SERVERS'] || 3).to_i

BASE_CLIENT_PORT    = 12181
BASE_QUORUM_PORT    = 12888
BASE_ELECTION_PORT  = 13888

# we bind to aliases of lo0 127.0.0.[2-6]
IPADDR_BASE_OCTET = 2

directory BASE_DATA_DIR = File.join(Dir.getwd, 'data')
directory BASE_CONF_DIR = File.join(Dir.getwd, 'etc')
directory BASE_LOG_DIR  = File.join(Dir.getwd, 'log')

CLIENT_CNX_FILE = File.join(BASE_CONF_DIR, 'zk-client.txt')

class ServerConfig < Struct.new(:idx, :srv_num, :client_port, :quorum_port, :election_port, :data_dir, :log_dir, :cfg_path, :myid_path, :ip_addr)
end

SERVER_CONFIGS = []

NUM_SERVERS.times do |idx|

  srv_num       = idx + 1
  client_port   = BASE_CLIENT_PORT + idx
  quorum_port   = BASE_QUORUM_PORT + idx
  election_port = BASE_ELECTION_PORT + idx
  data_dir      = File.join(BASE_DATA_DIR,  "srv#{srv_num}")
  log_dir       = File.join(BASE_LOG_DIR,   "srv#{srv_num}")
  cfg_path      = File.join(BASE_CONF_DIR,  "zoo#{srv_num}.cfg")
  myid_path     = File.join(data_dir, 'myid')
  ip_addr       = "127.0.0.#{IPADDR_BASE_OCTET + idx}"

  SERVER_CONFIGS << ServerConfig.new(idx, srv_num, client_port, quorum_port, election_port, data_dir, log_dir, cfg_path, myid_path, ip_addr)
end

# oooh! i hope he brings me a pony!
SERVER_CLAUSE = SERVER_CONFIGS.map do |cfg|
  "server.#{cfg.srv_num}=localhost:#{cfg.quorum_port}:#{cfg.election_port}"
end.join("\n")

CLIENT_CONNECTION_STR = SERVER_CONFIGS.map { |cfg| "localhost:#{cfg.client_port}" }.join(',')

SERVER_CONFIGS.each do |cfg|
  directory cfg.data_dir
  task cfg.data_dir => BASE_DATA_DIR

  directory cfg.log_dir
  task cfg.log_dir => BASE_LOG_DIR

  file cfg.cfg_path => BASE_CONF_DIR do
    File.open(cfg.cfg_path, 'w') do |fp|
      fp.puts <<-EOS
tickTime=2000
dataDir=#{cfg.data_dir}
clientPort=#{cfg.client_port}
maxClientCnxns=100
initLimit=5
syncLimit=2
#{SERVER_CLAUSE}
      EOS
      fp.fsync
    end
  end

  file cfg.myid_path => cfg.data_dir do
    File.open(cfg.myid_path, 'w') do |fp|
      fp.write(cfg.srv_num.to_s)
      fp.fsync
    end
  end

  log4jprops_path = File.join(BASE_CONF_DIR, 'log4j.properties')

  file log4jprops_path => ['log4j.properties', BASE_CONF_DIR] do
    cp 'log4j.properties', log4jprops_path
  end

  task_name = "srv_#{cfg.srv_num}"

  file CLIENT_CNX_FILE => BASE_CONF_DIR do
    File.open(CLIENT_CNX_FILE, 'w') { |fp| fp.puts(CLIENT_CONNECTION_STR); fp.fsync }
  end

  task task_name => [cfg.cfg_path, cfg.myid_path, cfg.log_dir, log4jprops_path, CLIENT_CNX_FILE]

  task :setup => task_name

  task "start_#{task_name}" do
    env = { 
      'ZOO_ROOT'    => ZOO_ROOT,
      'ZOO_SRV_NUM' => cfg.srv_num.to_s,
      'ZOO_LOG_DIR' => cfg.log_dir,
      'ZOO_CFG'     => cfg.cfg_path,
    }

    exec(env, 'ruby', 'start-zk.rb')
  end
end

task :clobber do
  rm_rf([BASE_DATA_DIR, BASE_CONF_DIR, BASE_LOG_DIR])
end

def is_leader?(cfg)
  TCPSocket.open('localhost', cfg.client_port) do |sock|
    sock.puts('srvr')
    while line = sock.gets
      line.chomp!
      if line =~ /^Mode: leader/
        return true
      end
    end
  end

  return false
rescue Errno::ECONNREFUSED
end

def find_leader!
  require 'socket'

  SERVER_CONFIGS.each do |cfg|
    if is_leader?(cfg)
      $stderr.puts "leader found! #{cfg.inspect}"
      return
    end
  end

  $stderr.puts "could not determine leader!"
end

task :find_leader do
  find_leader!
end

