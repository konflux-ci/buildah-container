#!/bin/bash

# Attach migration file to given task bundle and task_version.
# Arguments: task_bundle, task_version, migration_file 
# migration_file is the path of migration script file. For example: /var/workdir/source/task/deprecated-image-check/0.5/migrations/0.5.sh
# task_version is the version of task. For example: 0.3
# attach_migration_file "${task_bundle}" "${task_version}" "${migration_file}"
# default docker auth path will be used for access to docker.io registry
attach_migration_file() {
    local -r task_bundle=$1
    local -r task_version=$2
    local -r migration_file=$3

    local -r ARTIFACT_TYPE_TEXT_XSHELLSCRIPT="text/x-shellscript"
    local -r ANNOTATION_IS_MIGRATION="dev.konflux-ci.task.is-migration"
    # Check if task bundle has an attached migration file.
    local filename
    local found=
    local artifact_refs

    # List attached artifacts, that have specific artifact type and annotation.
    # Then, find out the migration artifact.
    #
    # Minimum version oras 1.2.0 is required for option --format
    artifact_refs=$(
        oras discover "$task_bundle" --artifact-type "$ARTIFACT_TYPE_TEXT_XSHELLSCRIPT" --format json | \
        jq -r "
            .manifests[]
            | select(.annotations.\"${ANNOTATION_IS_MIGRATION}\" == \"true\")
            | .reference"
    )
    while read -r artifact_ref; do
        if [ -z "$artifact_ref" ]; then
            continue
        fi
        filename=$(
            retry oras pull --format json "$artifact_ref" | jq -r "
                .files[]
                | select(.annotations.\"org.opencontainers.image.title\" == \"${task_version}.sh\")
                | .annotations.\"org.opencontainers.image.title\"
                "
        )

        if [ -n "$filename" ]; then
            if diff "$filename" "$migration_file" >/dev/null; then
                found=true
                break
            else
                echo "error: task bundle $task_bundle has migration artifact $artifact_ref, but the migration content is different: $filename" 1>&2
                exit 1
            fi
        fi
    done <<<"$artifact_refs"

    if [ -n "$found" ]; then
        return 0
    fi


    (
        cd "${migration_file%/*}"
        retry oras attach \
            --artifact-type "$ARTIFACT_TYPE_TEXT_XSHELLSCRIPT" \
            --annotation "${ANNOTATION_IS_MIGRATION}=true" \
            "$task_bundle" "${migration_file##*/}"
    )

    subshell_status=$?
    if [[ $subshell_status -ne 0 ]]; then
        echo "failed to attach migration script file to $task_bundle"
        exit 1
    fi

    echo
    echo "Attached migration file ${migration_file} to ${task_bundle}"

    return 0
}
