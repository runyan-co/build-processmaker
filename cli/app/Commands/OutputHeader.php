<?php

namespace ProcessMaker\Cli\Commands;

use Illuminate\Console\Scheduling\Schedule;
use LaravelZero\Framework\Commands\Command;

class OutputHeader extends Command
{
    /**
     * The signature of the command.
     *
     * @var string
     */
    protected $signature = 'output:header {input}';

    /**
     * The description of the command.
     *
     * @var string
     */
    protected $description = 'Output input as a styled header';

    /**
     * Execute the console command.
     *
     * @return mixed
     */
    public function handle()
    {
        $this->newLine();

        $this->alert($this->argument('input'));
    }
}
