class MessagesController < ApplicationController
  before_action :authenticate_user!

  def index
    # @messages = Message.where('author_id != ?', current_user.id).order(sent: :desc)
    @messages = Message.where('read IS NOT NULL').order(sent: :desc)
    @new_messages = Message.where('read IS NULL').order(sent: :desc)
  end

  def show
    @message = Message.find(params[:id])
    if @message.author != current_user  || @message.reciever != current_user
      redirect_to message
    end
    if @message.reciever == current_user
      @message.read = DateTime.now
      @message.save
    end
  end

  def new
    @message ||= Message.new
    if params[:id] != nil
      @message.reciever = User.find(params[:id])
    end
    @message.content = "" if @message.content.nil?
  end

  
  def create
    handle_form_submit(params, 'new')
  end

  def process_new_video(image) ## Image model used for all media
    blob_path = image_path(image)
    "\n\n<video controls><source src=\"#{blob_path}\" type=\"video/mp4\"></video>"
  end

  def process_new_audio(image) ## Image model used for all media
    blob_path = image_path(image)
    "\n\n<audio controls><source src=\"#{blob_path}\" type=\"audio/mpeg\"></audio>"
  end


  ## takes a saved Image object, returns the markdown content to refer to the image
  def process_new_image(image)
    blob_path = path_for(image.blob)
    image_meta = ActiveStorage::Analyzer::ImageAnalyzer::ImageMagick.new(image.blob).metadata
    if image_meta[:width] > 1600 #resize at lower quality with link
      return "<a href=\"#{image_path(image)}\"><img src=\"#{image_resized_path(image)}\"></img></a>"
    else #simple full image
      return "<img src=\"#{image_path(image)}\"></img>"
    end
  end

  private

  def image_path(image)
    "/images/raw/#{image.id}/#{image.blob.filename.to_s}"
  end

  def image_resized_path(image)
    "/images/resized/#{image.id}/#{image.blob.filename.to_s}"
  end
  
  def handle_form_submit(params, view)
    @message = message_from_form(params)
    puts @message.inspect
    if params[:commit] == "Завантажити медіа"
      if !(params[:message][:pic].nil?)
        begin
          @image = Image.new
          @image.blob.attach params[:message][:pic]
          @image.save
          file_ext = path_for(@image.blob).split(".").last.downcase
          if (file_ext == "mp3")
            @message.content += process_new_audio(@image)
          elsif ["mp4","mov","hevc"].include? file_ext
            @message.content += process_new_video(@image)
          else
            @message.content += process_new_image(@image)
          end
        rescue => e
          @image.destroy
          upload_filename = ""
          begin
            upload_filename = path_for(@image.blob).split("/").last
          rescue
          end
          Rails.logger.error "Error uploading #{upload_filename}"
          Rails.logger.error e.backtrace.join("\n") if e.backtrace
          flash.now[:alert] = "Error uploading #{upload_filename}: #{e}"
        end
      else # attachment does not exist
        flash.now[:alert] = "You did not choose a file to upload"
      end
      render view
    else
      u = User.find_by(name: params[:message][:reciever].strip)
      if u.nil?
        flash[:alert] = "Такого користувача не існує"
        render view
      else
        @message.save
        redirect_to @message
      end
    end
  end

  def message_from_form(params)
    message = Message.find_by(id: params[:id]) || Message.new
    message.sent = DateTime.now
    message.content = params[:message][:content]
    message.author = current_user
    u = User.find_by(name: params[:message][:reciever])
    unless u.nil?
      message.reciever = u
    end
    message
  end
  
  def path_for(obj)
    url = url_for(obj)
    "/#{url.split("/",4)[3]}"
  end

end
