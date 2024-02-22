class ApplicationController < ActionController::Base
  private

  def redirect_params
    params.to_unsafe_h.except(:action, :authenticity_token, :controller, :message)
  end
end
