class MessagesController < ApplicationController
  before_action :authenticate_user!

  def index
    @new_messages = Message.where('reciever_id = ?', current_user.id).where('read IS NULL').order(sent: :desc)
    @friends = Message.where('reciever_id = ?', current_user.id).select("author_id, count(*)-count(read) as i").group("author_id")
  end

  def show
    @message = Message.find(params[:id])
    if @message.author == current_user  || @message.reciever == current_user
      if @message.reciever == current_user
        @message.read = DateTime.now
        @message.save
      end
    else
      redirect_to :messages
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

  def dm
     @message = Message.new
     @message.reciever = User.find(params[:id])
     @messages = Message.where('reciever_id = ? OR author_id = ?', current_user.id, current_user.id).where('reciever_id = ? OR author_id = ?', params[:id], params[:id]).order(sent: :desc).page(params[:page])
     Message.where('reciever_id = ?', current_user.id).update_all(:read => DateTime.now)
  end

  def dm_create
    @messages = Message.where('reciever_id = ? OR author_id = ?', current_user.id, current_user.id).where('reciever_id = ? OR author_id = ?', params[:id], params[:id]).order(sent: :desc).page(params[:page])
    handle_form_submit(params, 'dm')
  end

  def dm_search
    u = User.find_by(name: params[:search_name])
    if u == nil
      flash.now[:alert] = "You did not choose a file to upload"
      redirect_to :messages
    else
      redirect_to dm_path(:id => u.id)
    end
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
    if image_meta[:width] > 800 #resize at lower quality with link
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
      render :dm, id: params[:id]
    else
      @message.save
      redirect_to :dm, id: params[:id]
    end
  end

  def message_from_form(params)
    message = Message.new
    message.sent = DateTime.now
    message.content = params[:message][:content]
    message.author = current_user
    message.reciever = User.find(params[:id])
    message
  end
  
  def path_for(obj)
    url = url_for(obj)
    "/#{url.split("/",4)[3]}"
  end

end
