#!/bin/bash
# Inject an ICM (image content manifest) file with content sets for backwards compatibility
#
# https://github.com/containerbuildsystem/atomic-reactor/blob/master/atomic_reactor/schemas/content_manifest.json
#
# This is not a file we want to inject always into the future, but older Red
# Hat build systems injected a file like this and some third-party scanners
# depend on it in order to map rpms found in each layer to CPE ids, to match
# them with vulnerability data. In the future, those scanners should port to
# using the dnf db and/or SBOMs to make that same match. Consider this
# deprecated.
#
# This is only possible for images built hermetically with prefetch

set -euo pipefail

CONTAINERFILE="${1}"
PREFETCH_SBOM="${2}"
OUTPUT_DIRECTORY="${3:-.}"

icm_filename="content-sets.json"
icm_output_location="${OUTPUT_DIRECTORY}/${icm_filename}"
# Note this used to be /root/buildinfo/content_manifests but is now /usr/share/buildinfo for compatibility
# with bootc/ostree systems. Ref https://issues.redhat.com/browse/KONFLUX-6844
location_in_container="/usr/share/buildinfo/${icm_filename}"


echo "Checking if ${PREFETCH_SBOM} exists."

if [ ! -f "${PREFETCH_SBOM}" ]; then
  echo "Could not find prefetched sbom. No content_sets found for ICM"
  exit 0
fi

echo "Preparing construction of content-sets.json to be placed at $location_in_container in the image"
cat >${icm_output_location} <<EOF
{
    "metadata": {
	"icm_version": 1,
	"icm_spec": "https://raw.githubusercontent.com/containerbuildsystem/atomic-reactor/master/atomic_reactor/schemas/content_manifest.json",
	"image_layer_index": 0
    },
    "from_dnf_hint": true,
    "content_sets": []
}

EOF

while IFS='' read -r content_set;
do
  if [ "${content_set}" != "" ]; then
    jq --arg content_set "$content_set" '.content_sets += [$content_set]' ${icm_output_location} > content-sets.json.tmp
    mv content-sets.json.tmp ${icm_output_location}
  fi
done <<< "$(
    jq -r '
        if .bomFormat == "CycloneDX" then
            .components[].purl
        else
            .packages[].externalRefs[]? | select(.referenceType == "purl") | .referenceLocator
        end' ${PREFETCH_SBOM} |
    grep -o -P '(?<=repository_id=).*(?=(&|$))' |
    sort -u
)"

echo "Constructed the following:"
cat ${icm_output_location}

echo "Appending a COPY command to the Containerfile"

echo "COPY $icm_filename $location_in_container" >> "${CONTAINERFILE}"
