#!/usr/bin/env php
<?php

declare(strict_types=1);

require_once __DIR__.'/bootstrap.php';

try {
	// Look for either PM_DIRECTORY as an env
	// variable and if we don't find that, look
	// for an argument passed
	if ((false === ($dir = getenv('PM_DIRECTORY'))) && false === ($dir = ($argv[1] ?? false))) {
		throw new DomainException('Path to app working directory not provided as argument or found as env var PM_DIRECTORY');
	}

	if (!is_string($dir) || !is_dir($dir)) {
		throw new RuntimeException("Invalid path to app work directory: {$dir}");
	}

	if (!is_file($composer = "{$dir}/composer.json")) {
        throw new RuntimeException("Invalid path to app composer.json: {$composer}");
	}

	// Look for an existing dotfile with
	// the hash of our composer.json
    $has_existing_hash = is_file($hash_file = "{$dir}/.composer-hash");

	// Hash the current composer.json
	$new_hash = md5(file_get_contents($composer, true));

	if ($has_existing_hash) {
        // Grab the existing hash
        $existing_hash = file_get_contents($hash_file, true);

        // Compare the two to determine if
        // composer.json has changed
        $output = $existing_hash === $new_hash ? 0 : 1;
	} else {
		// No hash means it didn't exist before,
		// so we can only create the file and
		// return a default of false since there's
		// nothing to compare it to
		$output = 0;
	}

    // Update or create the hash file
    file_put_contents($hash_file, $new_hash);

	$exitCode = 0;
} catch (Throwable $exception) {
    $output = $exception->getMessage();

    $exitCode = 1;
} finally {
	echo ($output ?? '').PHP_EOL;

    exit($exitCode ?? 1);
}

