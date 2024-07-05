# konflux-ci/buildah

This is a rebuild of [containers/buildah](https://github.com/containers/buildah) for use in Konflux-CI. Two images are produced by this repository. One is a simple rebuild of `buildah` and is available at [quay.io/konflux-ci/buildah:latest](https://quay.io/konflux-ci/buildah). The other is oriented at customizing the behavior of `buildah` within Tekton tasks and is available at [quay.io/konflux-ci/buildah-task:latest](https://quay.io/konflux-ci/buildah-task).

## Updating the git submodule

```bash
git init buildah
cd buildah
git checkout main && git pull
cd ..
```

If you want to have a `Verified` commit, it appears that you need to include some other content with the submodule update.
