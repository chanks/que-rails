def append_to_file(file, text)
  File.open(file, 'a') { |f| f.puts text }
end

def in_path(path, &block)
  Bundler.with_clean_env { Dir.chdir(path, &block) }
end

def rails_runner(ruby, options = {})
  in_path($app_copy_path) { `#{options[:variables]} rails r '#{ruby}'`.strip }
end
