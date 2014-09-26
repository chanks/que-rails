# que-rails

`que-rails` contains assorted tools that integrate the [Que job queue](https://github.com/chanks/que) into a Rails application. It provides rake tasks and a railtie that handles spinning up the background worker pool.

This document covers basic information on setting up and using Que in a standard Rails application, and assumes you're using Rails 4. *`que-rails` isn't tested with versions of Rails before 4, and may or may not work with them.* For information on more advanced usage of Que, see its [documentation](https://github.com/chanks/que/tree/master/docs).

## Installation

Add this line to your application's Gemfile:

    gem 'que-rails'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install que-rails

## Usage

First, generate and run a migration for the `que_jobs` table.

    $ bin/rails generate que:install
    $ bin/rake db:migrate

Create a class for each type of job you want to run:

``` ruby
# app/jobs/charge_credit_card.rb
class ChargeCreditCard < Que::Job
  # Default settings for this job. These are optional - without them, jobs
  # will default to priority 100 and run immediately.
  @priority = 10
  @run_at = proc { 1.minute.from_now }

  def run(user_id, options)
    # Do stuff.
    user = User.find(user_id)
    card = CreditCard.find(options[:credit_card_id])

    ActiveRecord::Base.transaction do
      # Write any changes you'd like to the database.
      user.update :charged_at => Time.now
      card.update :charged_at => Time.now

      # It's best to destroy the job in the same transaction as any other
      # changes you make. Que will destroy the job for you after the run
      # method if you don't do it yourself, but if your job writes to the
      # DB but doesn't destroy the job in the same transaction, it's
      # possible that the job could be repeated in the event of a crash.
      destroy
    end
  end
end
```

See the docs on [how to write a reliable job](https://github.com/chanks/que/blob/master/docs/writing_reliable_jobs.md) for more information on writing different types of jobs safely.

Queue your job. Again, it's best to do this in a transaction with other changes you're making. Also note that any arguments you pass will be serialized to JSON and back again, so stick to simple types (strings, integers, floats, hashes, and arrays).

``` ruby
ActiveRecord::Base.transaction do
  # Persist credit card information
  card = CreditCard.create(params[:credit_card])
  ChargeCreditCard.enqueue(current_user.id, :credit_card_id => card.id)
end
```

You can also add options to run the job after a specific time, or with a specific priority:

``` ruby
# The default priority is 100, and a lower number means a higher priority. 5 would be very important.
ChargeCreditCard.enqueue current_user.id, :credit_card_id => card.id, :run_at => 1.day.from_now, :priority => 5
```

To determine what happens when a job is queued, you can set Que's mode in your application configuration. There are a few options for the mode:

  * `config.que.mode = :off` - In this mode, queueing a job will simply insert it into the database - the current process will make no effort to run it. You should use this if you want to use a dedicated process to work tasks (there's a rake task to do this, see below). This is the default when running `bin/rails console`.
  * `config.que.mode = :async` - In this mode, a pool of background workers is spun up, each running in their own thread. This is the default when running `bin/rails server`. See the docs for [more information on managing workers](https://github.com/chanks/que/blob/master/docs/managing_workers.md).
  * `config.que.mode = :sync` - In this mode, any jobs you queue will be run in the same thread, synchronously (that is, `MyJob.enqueue` runs the job and won't return until it's completed). This makes your application's behavior easier to test, so it's the default in the test environment.

If you're using ActiveRecord to dump your database's schema, you'll probably want to [set schema_format to :sql](http://guides.rubyonrails.org/migrations.html#types-of-schema-dumps) so that Que's table structure is managed correctly.

### Forking Servers

If you want to run a worker pool in your web process and you're using a forking webserver like Phusion Passenger (in smart spawning mode), Unicorn or Puma (in some configurations), you'll want to set `Que.mode = :off` in your application configuration and only start up the worker pool in the child processes after the DB connection has been reestablished.

#### Puma

    # config/puma.rb
    on_worker_boot do
      ActiveRecord::Base.establish_connection

      Que.mode = :async
    end

#### Unicorn

    # config/unicorn.rb
    after_fork do |server, worker|
      ActiveRecord::Base.establish_connection

      Que.mode = :async
    end

#### Phusion Passenger

    # config.ru
    if defined?(PhusionPassenger)
      PhusionPassenger.on_event(:starting_worker_process) do |forked|
        if forked
          Que.mode = :async
        end
      end
    end

### Other ORMs

If you're using an ORM other than ActiveRecord, you'll need to pass Que the connection manually. For instance, if you're using Sequel, you could do this after you initialize the database connection:

    # config/initializers/sequel.rb
    DB = Sequel.connect(ENV['DATABASE_URL'])
    Que.connection = DB

### Rake Tasks

If you don't want to burden your web processes with too much work and want to run workers in a background process instead, similar to how most other queues work, `que-rails` provides a rake task:

    # Run a pool of 4 workers:
    rake que:work

    # Or configure the number of workers:
    QUE_WORKER_COUNT=8 rake que:work

Other options available via environment variables are `QUE_QUEUE` to determine which named queue jobs are pulled from, and `QUE_WAKE_INTERVAL` to determine how long workers will wait to poll again when there are no jobs available. For example, to run 2 workers that run jobs from the "other_queue" queue and wait a half-second between polls, you could do:

    QUE_QUEUE=other_queue QUE_WORKER_COUNT=2 QUE_WAKE_INTERVAL=0.5 rake que:work

### Additional Configuration

You can use the config.que object in your application config files to do whatever other setup you'd like. For example, you'll probably want to define an error handler, in order to pass errors raised by jobs to whatever tracking system you use:

    config.que.error_handler = proc { |error| ... }

You can also manually set the number of workers in each process:

    config.que.worker_count = 8

### Thread Safety

If your application code is not thread-safe, you won't want any workers to be processing jobs while anything else is happening in the Ruby process. So, you'll want to turn the worker pool off by default:

    config.que.mode = :off

This will prevent Que from trying to process jobs in the background of your web processes. In order to actually work jobs, you'll want to run a single worker at a time, and to do so via a separate rake task, like so:

    QUE_WORKER_COUNT=1 rake que:work

## Gem TODO

- Spec multiple versions of Rails, not just one.
- Spec the `rake que:work` task and its various options.
- Spec the generator more thoroughly.
- Spec that things don't fail when ActiveRecord isn't being used.
- Spec that Que can be configured successfully in an initializer or in the application or environment config files. This includes things like wake_interval, worker_count, etc.
- Spec that the worker pool starts up when Rails is running as a server, but not when running as a console or when running other rake tasks (like `db:migrate` or `routes`).
- Spec that the code samples for using Que with forking webservers all work (Unicorn, Phusion Passenger, Puma).
- Add handlers for common error services (Honeybadger, etc).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/que-rails/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
