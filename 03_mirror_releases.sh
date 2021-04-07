#!/bin/bash
# Create Disconnected Registry
# Source: https://access.redhat.com/articles/5489341

source 0_vars

#  add the login credentials of our disconnected registry to our existing pull secret
echo "${PULL_SECRET}" | jq ".auths += {\"${LOCAL_REGISTRY}\": {\"auth\": \"${SECRET}\",\"email\": \"noemail@localhost\"}}" > ${LOCAL_SECRET_JSON}

# Podman login
GODEBUG=x509ignoreCN=0 podman login ${HOSTNAME}:5000 --authfile ${LOCAL_SECRET_JSON}

# Mirror GA Release
GODEBUG=x509ignoreCN=0 oc adm -a ${LOCAL_SECRET_JSON} release mirror \
--from=${UPSTREAM_REGISTRY}/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE} \
--to=${LOCAL_REGISTRY}/ocp4 \
--to-release-image=${LOCAL_REGISTRY}/ocp4/release:${OCP_RELEASE}
