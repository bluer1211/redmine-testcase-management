class TestPlansController < ApplicationController

  def index
    @plans = TestPlan.all
  end
end
