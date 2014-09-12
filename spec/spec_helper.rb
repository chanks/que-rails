puts "Testing Que's integration with #{`rails -v`}"

$test_app_path  = "spec/tmp/test_app"
$fresh_app_path = "spec/tmp/fresh_app"

FileUtils.rm_rf($test_app_path)
FileUtils.rm_rf($fresh_app_path)

# Drop spec directory.
directory = File.dirname(__FILE__).split('/')[0..-2].join('/')

# Skip bundle install until we add que-rails.
`rails new #{$test_app_path} -B -d postgresql`


File.open("#{$test_app_path}/Gemfile", 'a') do |f|
  f.puts "gem 'que-rails', :path => '#{directory}'"
end


Bundler.with_clean_env do
  Dir.chdir($test_app_path) do
    `bundle`
    `rails generate que:install`
    `rake db:drop`
    `rake db:create`
    `rake db:migrate`
  end
end

FileUtils.cp_r($test_app_path, $fresh_app_path)

# def add_to_config(str)
#   environment = File.read("#{$fresh_app_path}/config/application.rb")
#   if environment =~ /(\n\s*end\s*end\s*)\Z/
#     File.open("#{$fresh_app_path}/config/application.rb", 'w') do |f|
#       f.puts $` + "\n#{str}\n" + $1
#     end
#   end
# end
