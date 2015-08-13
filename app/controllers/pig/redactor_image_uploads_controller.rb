module Pig
  class RedactorImageUploadsController < ApplicationController

    load_and_authorize_resource if respond_to?(:load_and_authorize_resource)
    skip_before_filter :verify_authenticity_token, only: :create

    def create
      @redactor_upload = RedactorImageUpload.new(file: params[:file], file_type: params[:file_type])
      if @redactor_upload.save
        filelink = @redactor_upload.file.url
      else
        filelink = ActionController::Base.helpers.asset_path('redactor_image_upload_error.png')
      end
      # Render as text, not json, to prevent response being wrapped in <pre> tag
      render text: {filelink: filelink, filename: @redactor_upload.file.name}.to_json
    end

    def index
      respond_to do |format|
        format.json {render json: @redactor_uploads.where(file_type: 'image').collect{|ru| {image: ru.image.url, thumb: ru.image.thumb('110x80#').url}}}
      end
    end

  end
end
