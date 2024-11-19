#!/bin/bash

# Create a release by setting a git release tag onto master branch

script=$(basename "$0")
if [ "$#" -ne 1 ]; then
    echo "Create a release by setting a git release tag onto master branch"
    echo "Usage $script <x.y.z_blxx>"
    echo "<x.y.z_blxx> - release version string, see README"
    exit 1
fi

# Input validation
version_full=$1

REGEX_VERSION_BL='^\d+\.\d+\.\d+_bl\d{2}$'
if [[ "$version_full" =~ $REGEX_VERSION_BL ]]; then
    echo "Found version ${version_full}"
else
    echo "Version ${version_full} malformed, see README!"
    exit 1
fi

# Check repo status
if ! git diff-index --quiet HEAD ; then
    # Note: this ignores untracked files!
    echo "Git working directory not clean!"
    exit 1
fi

release_tag="$version_full"
git tag --list | grep $release_tag
if [ $? -eq 0 ]; then
    echo "Release git tag $release_tag already exists"
    exit 1
fi

if ! git checkout "master" ; then
    echo "Failed to checkout master branch"
    exit 1
fi

git tag "$release_tag"
if [ $? -ne 0 ]; then
    echo "Git tag $release_tag failed"
    exit 1
fi

echo "Pushing master branch to server"
git push
if [ $? -ne 0 ]; then
    echo "Git branch push failed"
    exit 1
fi

echo "Pushing release tag to server"
git push origin $release_tag
if [ $? -ne 0 ]; then
    echo "Git tag push $release_tag failed"
    exit 1
fi

echo "******"
echo "Success creating release!"
echo "******"
exit 0
