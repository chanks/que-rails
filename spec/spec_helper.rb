require 'sequel'

DB = Sequel.connect ENV['DATABASE_URL'] || "postgres:///que_rails_test_app_development"

require 'support/helpers'

puts "Testing Que's integration with #{`rails -v`}"

$test_app_path = "spec/tmp/que_rails_test_app"
$app_copy_path = "spec/tmp/app_copy"

FileUtils.rm_rf($test_app_path)
FileUtils.rm_rf($app_copy_path)

# Drop spec directory.
directory = File.dirname(__FILE__).split('/')[0..-2].join('/')

# Skip bundle install until we add que-rails.
`rails new #{$test_app_path} -B -d postgresql`

append_to_file "#{$test_app_path}/Gemfile", "gem 'que-rails', :path => '#{directory}'"

in_path $test_app_path do
  `bundle`
  `rails generate que:install`
  `rake db:drop`
  `rake db:create`
  `rake db:migrate`
end

FileUtils.cp_r($test_app_path, $app_copy_path)

# def add_to_config(str)
#   environment = File.read("#{$app_copy_path}/config/application.rb")
#   if environment =~ /(\n\s*end\s*end\s*)\Z/
#     File.open("#{$app_copy_path}/config/application.rb", 'w') do |f|
#       f.puts $` + "\n#{str}\n" + $1
#     end
#   end
# end
