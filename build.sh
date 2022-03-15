#!/bin/bash

export BUILD_VERSION=$(date | md5sum | awk '{print $1}')

echo "BUILD_VERSION=$BUILD_VERSION" > ./iac/.env

./gradlew clean build

rm -f ./backend/build/libs/*plain.war

