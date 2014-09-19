require 'spec_helper'

describe "Que::Rails::Railtie" do
  it "should set Que's logger to the Rails logger" do
    run_in_app('puts Que.logger == Rails.logger').should == 'true'
  end

  it "should use ActiveRecord's DB connection" do
    run_in_app('puts Que.execute("SELECT 1 AS one")').should == '{"one"=>1}'
  end

  it "should leave Que off by default when run as rails runner" do
    run_in_app('puts Que.mode.inspect').should == ':off'
  end
end
