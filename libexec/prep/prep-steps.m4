#!/bin/sh
#
# Docker Development Box preparation.
#

set -e

. "$(dirname $0)/common"


#
# Essentials
#


ifelse(__FAMILY/eval(__MAJOR >= 8),RedHat/1,

       # Some minimal builds of EL8+ install microdnf but not dnf.  Bootstrap
       # that if necessary.

       for DIR in $(echo "${PATH}" | sed -e 's/:/\n/g')
       do
	   if [ -x "${DIR}/dnf" ]
	   then
	       DNF_DIR="${DIR}"
	       break
	   fi
       done
       if [ -z "${DNF_DIR}" ]
       then
	   echo "Bootstrapping DNF"
	   microdnf install -y dnf
       fi

       install_pkg \
	   rpm \
	   dnf-plugins-core \
	   epel-release
      )

ifelse(__FAMILY/__MAJOR,RedHat/8,dnf config-manager --set-enabled powertools)
ifelse(__FAMILY/__MAJOR,RedHat/9,dnf config-manager --set-enabled crb)
ifelse(__FAMILY/__MAJOR,RedHat/7,yum update -y)
ifelse(__FAMILY/eval(__MAJOR >= 8),RedHat/1,dnf update -y)

ifelse(__FAMILY,Debian,
       sed -i -e 's/^\s*#\s*\(deb-src\s+.*\)$/\1/' /etc/apt/sources.list
       apt-get update
      )


install_pkg \
    procps \
    sudo


#
# Systemd
#

install_pkg systemd

# Some Debian variants don't include this by default.
ifelse(__FAMILY,Debian,
       install_pkg systemd-sysv
      )

cp ddb-entrypoint.target /etc/systemd/system/ddb-entrypoint.target
cp ddb-entrypoint.service /etc/systemd/system/ddb-entrypoint.service
cp ddb-entrypoint /
chmod +x /ddb-entrypoint
