<?php

namespace ProcessMaker\Cli\Commands;

use DomainException;
use RuntimeException;
use Illuminate\Support\Arr;
use Illuminate\Support\Str;
use LaravelZero\Framework\Commands\Command;

class GetEnterprisePackages extends Command
{
    /**
     * The signature of the command.
     *
     * @var string
     */
    protected $signature = 'packages:list
                            {--dir= : Directory containing the processmaker platform (optional) }';

    /**
     * The description of the command.
     *
     * @var string
     */
    protected $description = 'List all enterprise packages in the correct, installable order';

    /**
     * Get the home directory for the ProcessMaker install
     *
     * @return string
     *
     * @throws \DomainException
     */
    public function getProcessMakerHome() {
        return config('app.pm-directory')
            ?: $this->option('dir')
            ?? throw new DomainException('Path to processmaker platform not defined');
    }

    /**
     * Execute the console command.
     *
     * @return void
     * @throws \JsonException
     */
    public function handle(): void
    {
        $composer_json = $this->getComposerJson($this->getProcessMakerHome());

        // Sort and remove these packages with the corresponding name
        // found in the array. This way we can prepend them later
        // to ensure they'll be in the correct installation order
        $packages = collect(array_values(array_keys(
            Arr::get($composer_json, 'extra.processmaker.enterprise')
        )))->values()->sort();

        // These particular packages need to appear in a certain
        // order in the packages list
        $ordered_packages = [
            'package-savedsearch',
            'package-collections',
            'docker-executor-node-ssr',
            'connector-send-email',
            'packages',
        ];

        // Remove these packages to prepend them in the next step
        $packages = $packages->reject(function ($package) use ($ordered_packages) {
            return in_array($package, $ordered_packages, true);
        })->toArray();

        // Prepend the removed packages to make sure they're
        // installed first, assuming the returned order is
        // relied on for installation
        $packages = collect(array_merge(
            array_reverse($ordered_packages),
            $packages
        ));

        // Print each package name on a new line
        // with an end of line character
        $packages->each(fn ($package) => $this->line($package));
    }

    /**
     * @param  string  $path_to_composer_json
     *
     * @return array
     * @throws \JsonException
     */
    public function getComposerJson(string $path_to_composer_json): array
    {
        if (! is_dir($path_to_composer_json)) {
            throw new DomainException("Path to composer.json not found: {$path_to_composer_json}".PHP_EOL);
        }

        if (Str::endsWith($path_to_composer_json, 'composer.json')) {
            $path_to_composer_json = Str::replace('composer.json', '', $path_to_composer_json);
        }

        if (Str::endsWith($path_to_composer_json, '/')) {
            $path_to_composer_json = Str::replaceLast('/', '', $path_to_composer_json);
        }

        $composer_json_file = "{$path_to_composer_json}/composer.json";

        if (! file_exists($composer_json_file)) {
            throw new RuntimeException("Composer.json not found: {$composer_json_file}".PHP_EOL);
        }

        return json_decode(file_get_contents($composer_json_file), true, 512, JSON_THROW_ON_ERROR);
    }
}
