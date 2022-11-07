#!/usr/bin/env php
<?php

declare(strict_types=1);

if (PHP_SAPI !== "cli") {
    throw new RuntimeException(__FILE__.' must be run in a CLI context.');
}

require __DIR__.'/vendor/autoload.php';

use Illuminate\Support\Str;
use Illuminate\Support\Arr;

/**
 * Get the parsed composer json for a given path
 *
 * @param  string  $path_to_composer_json
 *
 * @return mixed
 * @throws \JsonException
 */
function getComposerJson(string $path_to_composer_json): array
{
    if (!is_dir($path_to_composer_json)) {
        throw new DomainException("Path to composer.json not found: {$path_to_composer_json}".PHP_EOL);
    }

    if (Str::endsWith($path_to_composer_json, 'composer.json')) {
        $path_to_composer_json = Str::replace('composer.json', '', $path_to_composer_json);
    }

    if (Str::endsWith($path_to_composer_json, '/')) {
        $path_to_composer_json = Str::replaceLast('/', '', $path_to_composer_json);
    }

    $composer_json_file = "{$path_to_composer_json}/composer.json";

    if (!file_exists($composer_json_file)) {
        throw new RuntimeException("Composer.json not found: {$composer_json_file}".PHP_EOL);
    }

    return json_decode(file_get_contents($composer_json_file), true, 512, JSON_THROW_ON_ERROR);
}

if (!($pm_directory = getenv('PM_DIRECTORY'))) {
    throw new DomainException('Necessary environment variable $PM_DIRECTORY not defined'.PHP_EOL);
}

try {
    $composer_json = getComposerJson($pm_directory);
    $packages = array_values(array_keys(Arr::get($composer_json,'extra.processmaker.enterprise')));

	foreach ($packages as $package) {
		echo $package.PHP_EOL;
	}

    $exitCode = 0;
} catch (Throwable $exception) {
    echo $exception->getMessage().PHP_EOL;

	$exitCode = 1;
} finally {
	exit($exitCode ?? 1);
}
