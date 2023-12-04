class MessagesController < ApplicationController
  def new
    render locals: {message: Message.new}
  end

  def create
    message = Message.new(message_params)

    if message.valid?
      redirect_to new_message_url(redirect_params), notice: "Message Created."
    else
      render :new, locals: {message: message}, status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:status, :subject, :content)
  end

  def redirect_params
    params.to_unsafe_h.except(:action, :authenticity_token, :controller, :message)
  end
end
