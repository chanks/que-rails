require 'spec_helper'

describe "Que::Rails::Railtie" do
  it "should set Que's logger to the Rails logger" do
    Bundler.with_clean_env do
      Dir.chdir($fresh_app_path) do
        `rails r 'puts Que.logger == Rails.logger'`.strip.should == 'true'
      end
    end
  end
end
