#!/bin/bash
# Create Disconnected Registry
# Source: https://access.redhat.com/articles/5489341

source 0_vars

# Create the Red Hat Operators Catalog
GODEBUG=x509ignoreCN=0 oc adm -a ${LOCAL_SECRET_JSON} catalog build \
--appregistry-org redhat-operators \
--from=registry.redhat.io/openshift4/ose-operator-registry:v${OPENSHIFT_MAJOR_RELEASE} \
--filter-by-os=${OS_ARCH} \
--to=$(hostname):5000/olm/redhat-operators:${CATALOG_BUILD_VERSION}i

# Mirror the Red Hat Operators Catalog 
GODEBUG=x509ignoreCN=0 oc adm -a ${LOCAL_SECRET_JSON} catalog mirror \
$(hostname):5000/olm/redhat-operators:${CATALOG_BUILD_VERSION}i \
$(hostname):5000 \
--index-filter-by-os=${OS_ARCH}
