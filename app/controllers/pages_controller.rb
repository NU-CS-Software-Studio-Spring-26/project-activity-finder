class PagesController < ApplicationController
  def welcome
    redirect_to activities_path if logged_in?
  end

  def terms; end
  def privacy; end
  def about; end
end
