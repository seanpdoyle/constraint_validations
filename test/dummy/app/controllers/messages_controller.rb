class MessagesController < ApplicationController
  def new
    render locals: {message: Message.new}
  end

  def create
    message = Message.new(params.require(:message).permit(:subject, :contents))

    if message.valid?
      redirect_back or_to: root_url
    else
      render :new, locals: {message: message}, status: :unprocessable_entity
    end
  end
end
