def append_to_file(file, text)
  File.open(file, 'a') { |f| f.puts text }
end

def in_path(path, &block)
  Bundler.with_clean_env { Dir.chdir(path, &block) }
end

def run_in_app(ruby)
  in_path($app_copy_path) { `rails r '#{ruby}'`.strip }
end
