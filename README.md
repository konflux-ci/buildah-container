# konflux-ci/buildah

A rebuild of [containers/buildah](https://github.com/containers/buildah) available at [quay.io/konflux-ci/buildah:latest](https://quay.io/konflux-ci/buildah).

## Updating the git submodule

```bash
git init buildah
cd buildah
git checkout main && git pull
cd ..
```

If you want to have a `Verified` commit, it appears that you need to include some other content with the submodule update.
