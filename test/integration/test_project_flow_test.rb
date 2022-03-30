require 'test_helper'
require File.expand_path('../../test_helper', __FILE__)

class TestProjectFlowTest < Redmine::IntegrationTest
  fixtures :projects, :users, :issues, :members, :member_roles, :roles, :issue_statuses,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
end
