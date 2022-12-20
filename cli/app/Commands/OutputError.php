<?php

namespace ProcessMaker\Cli\Commands;

use Illuminate\Console\Scheduling\Schedule;
use LaravelZero\Framework\Commands\Command;

class OutputError extends Command
{
    /**
     * The signature of the command.
     *
     * @var string
     */
    protected $signature = 'output:error {input}';

    /**
     * The description of the command.
     *
     * @var string
     */
    protected $description = 'Output the input as a styled error message';

    /**
     * Execute the console command.
     *
     * @return mixed
     */
    public function handle()
    {
        $this->newLine();

        $this->error($this->argument('input'));

        $this->newLine();
    }
}
