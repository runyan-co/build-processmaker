#!/usr/bin/env bash

export PM_VERSION=4.3.0-RC2

bash ./build-base-image.sh && bash ./build-app-image.sh
