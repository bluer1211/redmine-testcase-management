class TestCaseExecutionsController < ApplicationController

  include ApplicationsHelper

  before_action do
    prepare_user_candidates
  end

  def index
  end
end
