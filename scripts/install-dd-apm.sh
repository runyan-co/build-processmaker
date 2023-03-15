#!/usr/bin/env bash

##
# DataDog PHP Tracing
# https://docs.datadoghq.com/tracing/trace_collection/dd_libraries/php/?tab=containers#install-the-extension
##
curl -LO https://github.com/DataDog/dd-trace-php/releases/latest/download/datadog-setup.php
php datadog-setup.php --php-bin=all --enable-profiling
rm datadog-setup.php
