require 'spec_helper'

describe "Que::Rails::Railtie" do
  it "should set Que's logger to the Rails logger" do
    Bundler.with_clean_env do
      Dir.chdir($fresh_app_path) do
        `rails r 'puts Que.logger == Rails.logger'`.strip.should == 'true'
      end
    end
  end

  it "should use ActiveRecord's DB connection" do
    Bundler.with_clean_env do
      Dir.chdir($fresh_app_path) do
        `rails r 'puts Que.execute("SELECT 1 AS one")'`.strip.should == '{"one"=>1}'
      end
    end
  end
end
