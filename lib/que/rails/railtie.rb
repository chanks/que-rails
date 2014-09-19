module Que
  module Rails
    class Railtie < ::Rails::Railtie
      config.que = Que

      Que.logger     = proc { ::Rails.logger }
      Que.mode       = :sync if ::Rails.env.test?
      Que.connection = ::ActiveRecord if defined? ::ActiveRecord

      rake_tasks do
        load 'que/rails/rake_tasks.rb'
      end

      initializer 'que.setup' do
        ::ActiveSupport.on_load :after_initialize do
          # Only start up the worker pool if running as a server.
          Que.mode ||= defined?(::Rails::Server) ? :async : :off

          at_exit do
            if Que.mode == :async
              $stdout.puts "Finishing Que's current jobs before exiting..."
              Que.mode = :off
              $stdout.puts "Que's jobs finished, exiting..."
            end
          end
        end
      end
    end
  end
end
