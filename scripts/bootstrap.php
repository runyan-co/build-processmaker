<?php

declare(strict_types=1);

if (PHP_SAPI !== "cli") {
    throw new \RuntimeException(__FILE__.' must be run in a CLI context.');
}

require __DIR__.'/vendor/autoload.php';
