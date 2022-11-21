#!/usr/bin/env php
<?php

declare(strict_types=1);

require_once __DIR__.'/bootstrap.php';

use Illuminate\Encryption\Encrypter;

try {
    echo 'base64:'.base64_encode(
		Encrypter::generateKey(getenv('APP_CIPHER') ?? 'AES-256-CBC')
	).PHP_EOL;

	$exitCode = 0;
} catch (Throwable $exception) {
    echo $exception->getMessage().PHP_EOL;

    $exitCode = 1;
} finally {
    exit($exitCode ?? 1);
}
