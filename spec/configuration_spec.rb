require 'spec_helper'

describe "Que::Rails::Railtie" do
  it "should set Que's logger to the Rails logger" do
    rails_runner('puts Que.logger == Rails.logger').should == 'true'
  end

  it "should use ActiveRecord's DB connection" do
    rails_runner('puts Que.execute("SELECT 1 AS one")').should == '{"one"=>1}'
  end

  it "should leave Que off by default when run as rails runner" do
    rails_runner('puts Que.mode.inspect').should == ':off'
  end
end
