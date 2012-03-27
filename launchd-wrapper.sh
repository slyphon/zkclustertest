#!/bin/bash

if [ "x$JMXLOCALONLY" = "x" ]
then
    JMXLOCALONLY=false
fi

if [ "x$JMXDISABLE" = "x" ]
then
    echo "JMX enabled by default"
    # for some reason these two options are necessary on jdk6 on Ubuntu
    #   accord to the docs they are not necessary, but otw jconsole cannot
    #   do a local attach
    ZOOMAIN="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=$JMXLOCALONLY org.apache.zookeeper.server.quorum.QuorumPeerMain"
else
    echo "JMX disabled by user request"
    ZOOMAIN="org.apache.zookeeper.server.quorum.QuorumPeerMain"
fi

ZOO_ROOT=/opt/zookeeper
ZOO_LOG_DIR=/Users/slyphon/Library/Logs

ZOOCFGDIR=${ZOO_ROOT}/conf

ZOOCFG=${ZOOCFGDIR}/zoo.cfg

ZOO_LOG4J_PROP="INFO,CONSOLE"

if [[ ! -d "$ZOOCFGDIR" ]]; then
  echo "Error! $ZOOCFGDIR does not exist, sleeping for 10 then trying again" >&2
  sleep 10
  exit 0
fi

CLASSPATH="$ZOOCFGDIR:$CLASSPATH"

for i in ${ZOO_ROOT}/lib/*.jar; do
  CLASSPATH="$i:$CLASSPATH"
done

for i in ${ZOO_ROOT}/*.jar; do
  CLASSPATH="$i:$CLASSPATH"
done

JVMFLAGS="-server -Xmx256m -XX:+UseConcMarkSweepGC"

exec java \
  "-Dzookeeper.serverCnxnFactory=org.apache.zookeeper.server.NettyServerCnxnFactory" \
  "-Dzookeeper.log.dir=${ZOO_LOG_DIR}" \
  -cp "$CLASSPATH" \
  $JVMFLAGS $ZOOMAIN "$ZOOCFG"

