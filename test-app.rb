#!/usr/bin/env ruby

require 'rubygems'
require 'bundler'

require 'eventmachine'
require 'zk-eventmachine'
require 'logging'

include Logging.globally

Logging.logger.root.tap do |log|
  log.add_appenders(Logging.appenders.stderr)
  log.level = :debug
  log.debug { "log opened" }
end


ZK_CLIENT_FILE = File.expand_path('../etc/zk-client.txt', __FILE__)
ZK_CNX_STR = File.read(ZK_CLIENT_FILE).chomp.split(',')[0..2].join(',')

ZK_STATE_NAME_MAP = {
  expired_session:  ZookeeperConstants::ZOO_EXPIRED_SESSION_STATE,
  auth_failed:      ZookeeperConstants::ZOO_AUTH_FAILED_STATE,
  closed:           ZookeeperConstants::ZOO_CLOSED_STATE,
  connecting:       ZookeeperConstants::ZOO_CONNECTING_STATE,
  associating:      ZookeeperConstants::ZOO_ASSOCIATING_STATE,
  connected:        ZookeeperConstants::ZOO_CONNECTED_STATE,
}

ZK_STATE_INT_MAP = ZK_STATE_NAME_MAP.invert


class TestApp
  attr_reader :zk_client

  def initialize
    @zk_client = ZK::ZKEventMachine::Client.new(ZK_CNX_STR)
  end

  def state_handler(event)
    logger.info { "state_handler, event.state: #{ZK_STATE_INT_MAP[event.state]}, event: #{event.inspect}" }
  end

  def run
    trap('INT') do
      logger.fatal { 'trapped INT, exiting' }

      EM.next_tick do
        zk_client.close! do
          EM.stop_event_loop
        end
      end
    end

    EM.run do
      ZK_STATE_INT_MAP.keys.sort.each { |state| zk_client.event_handler.register_state_handler(state, &method(:state_handler)) }

      zk_client.connect do
        logger.debug "zk_client started"
      end
    end
  end
end


TestApp.new.run if __FILE__ == $0

