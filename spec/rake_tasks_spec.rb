require 'spec_helper'

describe "que-rails rake tasks" do
  it "should include a task for migrating Que's job table" do
    in_path($app_copy_path) do
      DB.table_exists?(:que_jobs).should be true
      `QUE_MIGRATE_VERSION=0 rake que:migrate`
      DB.table_exists?(:que_jobs).should be false
      `rake que:migrate`
      DB.table_exists?(:que_jobs).should be true

      DB[:que_jobs].insert(job_class: 'Que::Job')
      DB[:que_jobs].count.should == 1
      `rake que:clear`
      DB[:que_jobs].count.should == 0

      `rake que:drop`
      DB.table_exists?(:que_jobs).should be false
      `rake que:migrate`
      DB.table_exists?(:que_jobs).should be true
    end
  end
end
