# konflux-ci/buildah-task

This is an image that contains the tools and Bash scripts needed for the Konflux buildah task.
It is available at [quay.io/konflux-ci/buildah-task:latest](https://quay.io/konflux-ci/buildah-task).

## Building artifacts

Konflux triggers builds automatically for push events (if the relevant files change).
To see what files are considered relevant, check the `pipelinesascode.tekton.dev/on-cel-expression`
annotation in the PipelineRun files in `.tekton/`.

## Updating the git submodule

```bash
git init dockerfile-json
cd dockerfile-json
git checkout dev && git pull
cd ..
```

## Releasing images in Konflux

In order to reduce unnecessary updates to buildah image references in konflux-ci/build-definitions, we have disabled the auto-release of produced snapshots. This means that in order to trigger image reference updates with Renovate, we need to manually release the latest snapshot.

```bash
apiVersion: appstudio.redhat.com/v1alpha1
kind: Release
metadata:
 name: <unique-name-of-this-release>
 namespace: rhtap-build-tenant
spec:
 releasePlan: buildah-container
 snapshot: <application-snapshot-name>
```

While you can find the Snapshot via the Konflux UI, you can also identify the latest snapshot via the CLI:

```bash
$ kconfig=<path-to-kubeconfig> && for application in $(oc get applications --no-headers=true -o custom-columns=":metadata.name" --kubeconfig=$kconfig); do oc get snapshots -l "pac.test.appstudio.openshift.io/event-type in (push, Push),appstudio.openshift.io/application=${application}" --sort-by=.metadata.creationTimestamp --kubeconfig=$kconfig | tail -1; done | grep buildah-container
buildah-container-xcrf4   20d
```
