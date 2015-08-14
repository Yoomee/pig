module Pig
  class ContentPackagesController < ApplicationController

    rescue_from CanCan::AccessDenied do |exception|
      if action_name == 'show'
        instance_eval(&Pig.configuration.unpublished)
      else
        redirect_to pig.new_user_session_path
      end
    end

    layout 'layouts/application', only: [:show, :home]
    load_and_authorize_resource
    skip_load_resource :home
    # Define an around filter for all controller actions that could potentially be routed to from a permalink
    around_action :redirect_to_permalink, :only => ContentPackage.member_routes.collect{ |x| x[:action] }
    before_action :set_editing_user, only: [:create, :delete, :update, :destroy, :ready_to_review, :restore]

    def activity
      if request.xhr?
        page = params[:page] || 2
        if @content_package
          @activity_items = @content_package.activity_items.paginate(:page => page, :per_page => 5)
        else
          @activity_items = Pig::ActivityItem.where(:resource_type => "Pig::ContentPackage").paginate(:page => page, :per_page => 5)
        end
        @page = page.to_i + 1
      end
    end

    def children
    end

    def analytics
      user = service_account_user
      profile = user.accounts.first.profiles.first
      hash = {
        pageViewsCount: Visits.page_path(@content_package.permalink.full_path, profile).results(start_date: 7.days.ago).collect{|x| x.pageviews.to_i }.sum
      }
      render json: hash
    end

    def edit
      get_view_data
    end

    def create
      if @content_package.save
        redirect_to edit_content_package_path(@content_package)
      else
        render :action => 'new'
      end
    end

    def delete
      if @content_package.delete
        flash[:notice] = "Deleted \"#{@content_package}\" - #{view_context.link_to('Undo', restore_content_package_path(@content_package), :method => :put)}"
      else
        flash[:error] = "\"#{@content_package}\" couldn't be deleted"
      end
      redirect_to content_packages_path(:open => @content_package.parent)
    end

    def deleted
      @deleted_content_packages = ContentPackage.where("deleted_at IS NOT NULL").order("deleted_at DESC").paginate(:page => params[:page], :per_page => 50)
    end

    def destroy
      if @content_package.destroy
        flash[:notice] = "Destroyed \"#{@content_package}\""
      else
        flash[:error] = "\"#{@content_package}\" couldn't be destroyed"
      end
      redirect_to deleted_content_packages_path
    end

    def index
      @content_packages = @content_packages.root.includes(:children, :content_type, :author)
      if params[:open] && open_content_package = ContentPackage.find_by_id(params[:open])
        @open = [open_content_package] + open_content_package.parents
      end
      respond_to do |format|
        format.html
        format.js
      end
    end

    def new
      @content_package.content_type = Pig::ContentType.find_by_id(params[:content_type_id])
      @content_package.parent_id = params[:parent]
      @content_package.requested_by = current_user
      @content_package.review_frequency = 1
      @content_package.due_date = Date.today
      @content_types = ContentType.all.order('name')
    end

    def reorder
    end

    def remove_abandoned_sir_trevor_images
      # Not used for now, keep in case we want to turn this into a rake task later
      rich_content_chunks = @content_package.content_chunks.joins(:content_attribute).where(:content_attributes => {field_type: 'rich'}).pluck(:value)
      urls = []
      rich_content_chunks.each do |chunk|
        value = JSON.parse(chunk)['data']
        value.select! { |i| i['type'] == 'image' }
        value.each do |v|
          urls.append(v['data']['file']['url'])
        end
      end
      @content_package.sir_trevor_images.each do |stimg|
        unless urls.include? stimg.image.url
          stimg.destroy!
        end
      end
    end

    def restore
      @content_package.restore
      flash[:notice] = "Restored \"#{@content_package}\""
      redirect_to content_packages_path(:open => @content_package)
    end

    def save_order
      params[:children_ids].each_with_index do |child_id, position|
        ContentPackage.find(child_id).update_attribute(:position, position)
      end
      redirect_to content_packages_path(:open => @content_package.id)
    end

    def search
      if defined?(Riddle)
        term = Riddle.escape(params[:term])
      else
        term = params[:term]
      end
      render :json => ContentPackage.search(term).includes(:permalink).map { |cp| {
          id: cp.id,
          label: cp.name.truncate(60),
          value: cp.permalink_display_path,
          open_url: pig.content_packages_path(open: cp.id)
      }}
    end

    def show
      render_content_package_view
    end

    def home
      @content_package = instance_eval(&Pig.configuration.homepage)
      render_content_package_view
    end

    def ready_to_review
      get_view_data
      @content_package.status = "pending"
      update_content_package
    end

    def update
      get_view_data
      @content_package.skip_status_transition = true
      update_content_package
    end

    def upload_sir_trevor_attachment
      begin
        stimg = @content_package.sir_trevor_images.create(image: params[:attachment][:file], sir_trevor_uid: params[:attachment][:uid], filename: params[:attachment][:original_filename])
        render json: { file: { url: stimg.image.url, dragonfly_uid: stimg.image_uid } }, status: 200
      rescue => exception
        puts exception
        render json: { error: 'Upload failed' }, status: 500
      end
    end

    private
    def content_package_params
      params.require(:content_package).permit!
    end

    def get_view_data
      @persona_groups = Pig::PersonaGroup.all.includes(:personas)
      @activity_items = @content_package.activity_items.includes(:user, :resource).paginate(:page => 1, :per_page => 5)
      @non_meta_content_attributes = @content_package.content_attributes.where(:meta => false)
      @meta_content_attributes = @content_package.content_attributes.where(:meta => true)
    end

    def update_content_package
      # Because of the way pig uses method missing to update each content chunk just using
      # touch: true on the association would result in an update on the content package for every chunk
      # Because of this the updated_at time is set here

      previous_status = @content_package.status

      if @content_package.update_attributes(content_package_params)
        flash[:notice] = "Updated \"#{@content_package}\""
        if @content_package.status == 'published' && previous_status != 'published'
          @content_package.published_at = DateTime.now
          @content_package.save
        end
        redirect_to pig.edit_content_package_path(@content_package)
      else
        #TODO change to flash[:error] when the style has been made
        flash[:notice] = "Sorry there was a problem saving this page: #{@content_package.errors.full_messages.to_sentence}"
        render :action => 'edit'
      end
    end

    def render_content_package_view
      if template_exists?("pig/content_packages/views/#{@content_package.view_name}")
        render "pig/content_packages/views/#{@content_package.view_name}" and return
      end
    end

    def redirect_to_permalink
      # If the url matched a permalinkable content package route then it will have a param of :path
      if params[:path]
        if permalink = Permalink.find_from_url(params[:path])
          #If the permalink is active then just set the content package and yield to the original action.
          if permalink.active
            @content_package = ContentPackage.includes(:content_chunks => :content_attribute).find(permalink.resource_id)
            authorize! params[:action].to_sym, @content_package
            yield
          else
            # Otherwise redirect to the proper permalink so that we come back to this method and fall through the correct path.
            redirect_to permalink.resource.permalink.full_path + params_for_redirect, status: 301
          end
        else
          # If there isn't a matching permalink handle it with rails (Default is 404)
          raise ::ActionController::RoutingError.new('Not Found')
        end
      else
        if (@content_package && @content_package.permalink.nil?) || ContentPackage.member_routes.reject { |x| x[:action] == "show" }.any?{|x| x[:action] == params[:action]}
          yield
        else
          redirect_to @content_package.permalink.full_path + params_for_redirect, status: 301
        end
      end
    end

    def set_editing_user
      @content_package.editing_user = current_user
    end

    private

    def params_for_redirect
      significant_params = params.except(:action, :controller, :id, :path)
      significant_params.present? ? '?' + significant_params.to_query : ''
    end

    def service_account_user(scope="https://www.googleapis.com/auth/analytics.readonly")
      api_version = 'v3'
      cached_api_file = "analytics-#{api_version}.cache"

      ## Read app credentials from a file
      opts = YAML.load_file("ga_config.yml")

      ## Update these to match your own apps credentials in the ga_config.yml file
      service_account_email = opts['service_account_email']  # Email of service account
      key_file = opts['key_file']                            # File containing your private key
      key_secret = opts['key_secret']                        # Password to unlock private key
      @profileID = opts['profileID'].to_s                    # Analytics profile ID.

      @client = Google::APIClient.new(
      :application_name => opts['application_name'],
      :application_version => opts['application_version'])

      ## Load our credentials for the service account
      key = Google::APIClient::KeyUtils.load_from_pkcs12(key_file, key_secret)

      @client.authorization = Signet::OAuth2::Client.new(
      :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
      :audience => 'https://accounts.google.com/o/oauth2/token',
      :scope => 'https://www.googleapis.com/auth/analytics.readonly',
      :issuer => service_account_email,
      :signing_key => key)

      ## Request a token for our service account
      token = @client.authorization.fetch_access_token!

      oauth_client = OAuth2::Client.new("", "", {
        :authorize_url => 'https://accounts.google.com/o/oauth2/auth',
        :token_url => 'https://accounts.google.com/o/oauth2/token'
      })
      token = OAuth2::AccessToken.new(oauth_client, token['access_token'], expires_in: 1.hour)
      Legato::User.new(token)
    end
  end
end
