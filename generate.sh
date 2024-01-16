#!/bin/bash

set -euo pipefail

[[ ${V-} != 1 ]] || set -x

trap 'rm -rf ./build-*.json ./package.json ./package-lock.json ./node_modules' EXIT

install_dependencies() {
  npm install '@redocly/cli' '@openapi-contrib/openapi-schema-to-json-schema'
}

main() {
  install_dependencies
  openshift_version=4.12
  kubernetes_version=1.25

  oc get --raw /openapi/v2 >"./build-orig-$openshift_version.json"
  mkdir -p "./schemas/openshift-$openshift_version"
  npx '@redocly/cli' bundle "./build-orig-$openshift_version.json" --ext json --output "./build-bundled-$openshift_version.json"
  npx "@openapi-contrib/openapi-schema-to-json-schema" --input "./build-bundled-$openshift_version.json" --output "./schemas/openshift-$openshift_version/definitions.json"

  curl -sSLfo "./build-orig-$kubernetes_version.json" "https://raw.githubusercontent.com/kubernetes/kubernetes/v$kubernetes_version.0/api/openapi-spec/swagger.json"
  mkdir -p "./schemas/kubernetes-$kubernetes_version"
  npx '@redocly/cli' bundle "./build-orig-$kubernetes_version.json" --ext json --output "./build-bundled-$kubernetes_version.json"
  npx "@openapi-contrib/openapi-schema-to-json-schema" --input "./build-bundled-$kubernetes_version.json" --output "./schemas/kubernetes-$kubernetes_version/definitions.json"
}

main "$@"
