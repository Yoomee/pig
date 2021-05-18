module Pig
  module Admin
    class ContentPackagesController < Pig::Admin::ApplicationController

      rescue_from CanCan::AccessDenied do |exception|
        redirect_to pig.new_user_session_path
      end

      before_action :find_content_package, except: [
        :activity,
        :create,
        :archived,
        :destroy,
        :index,
        :new,
        :restore,
        :search
      ]
      before_action :set_editing_user, only: [
        :archive,
        :update,
        :ready_to_review
      ]
      before_action :set_paper_trail_whodunnit

      authorize_resource class: 'Pig::ContentPackage'
      skip_authorize_resource only: [:new, :destroy, :search, :restore]

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
        begin
          user = service_account_user
          profile = user.accounts.first.profiles.first
          analytics = Pig::Analytics.new(Visits.page_path(@content_package.permalink.full_path, profile).results(start_date: params[:period].to_i.days.ago))
          render json: analytics.as_json
        rescue
          render json: { error: "Ooops, you haven't setup the Google analytics configuration properly. See the readme!" }, status: 500
        end
      end

      def edit
        get_view_data
      end

      def create
        @content_package = Pig::ContentPackage.new(content_package_params)
        set_editing_user
        authorize! :create, @content_package
        #@content_package.quick_build_permalink
        if @content_package.save
          if params[:close]
            redirect_to admin_content_packages_path(open: @content_package.id)
          else
            redirect_to edit_admin_content_package_path(@content_package)
          end
        else
          flash[:notice] = "Error: #{@content_package.errors.full_messages.to_sentence}"
          render :action => 'new'
        end
      end

      def archive
        if @content_package.archive
          flash[:notice] = "#{t('actions.archived')} \"#{@content_package}\" - #{view_context.link_to('Undo', restore_admin_content_package_path(@content_package.id), :method => :put)}"
        else
          flash[:error] = "\"#{@content_package}\" couldn't be #{t('actions.archived').downcase}"
        end
        redirect_to pig.admin_content_packages_path(:open => @content_package.parent)
      end

      def archived
        @archived_content_packages = Pig::ContentPackage.archived.paginate(:page => params[:page], :per_page => 50)
      end

      def destroy
        @content_package = Pig::ContentPackage.unscoped.find(params[:id])
        set_editing_user
        authorize! :destroy, @content_package
        if @content_package.destroy
          flash[:notice] = "Destroyed \"#{@content_package}\""
        else
          flash[:error] = "\"#{@content_package}\" couldn't be destroyed"
        end
        redirect_to pig.archived_admin_content_packages_path
      end

      def index
        @content_packages = Pig::ContentPackage.roots.includes(:children, :content_type, :author)
        if params[:open] && open_content_package = Pig::ContentPackage.find_by_id(params[:open])
          @open = [open_content_package] + open_content_package.parents
        end
        respond_to do |format|
          format.html
          format.js
        end
      end

      def new
        @content_package = Pig::ContentPackage.new
        @content_package.content_type = Pig::ContentType.find_by_id(params[:content_type_id])
        @content_package.parent_id = params[:parent]
        @content_package.requested_by = current_user
        @content_package.next_review = Date.today + 6.months
        @content_package.due_date = Date.today
        @content_types = Pig::ContentType.all.order('name')
        authorize!(:new, @content_package)
      end

      def reorder
      end

      def restore
        @content_package = Pig::ContentPackage.unscoped.find(params[:id])
        set_editing_user
        authorize! :restore, @content_package
        @content_package.restore
        flash[:notice] = "Restored \"#{@content_package}\""
        redirect_to pig.admin_content_packages_path(:open => @content_package)
      end

      def save_order
        params[:children_ids].each_with_index do |child_id, position|
          Pig::ContentPackage.find(child_id).update_attribute(:position, position)
        end
        redirect_to admin_content_packages_path(:open => @content_package.id)
      end

      def search
        if defined?(Riddle)
          term = Riddle.escape(params[:term])
        else
          term = params[:term]
        end
        render :json => Pig::ContentPackage.search(term).includes(:permalink).map { |cp| {
            id: cp.id,
            label: cp.name.truncate(60),
            value: cp.permalink_display_path,
            open_url: pig.admin_content_packages_path(open: cp.id)
        }}
      end

      def ready_to_review
        get_view_data
        @content_package.status = 'pending'
        update_content_package
      end

      def update
        get_view_data
        update_content_package
      end

      private
      def content_package_params
        params.require(:content_package).permit!
      end

      def find_content_package(scope = Pig::ContentPackage)
        @content_package = Pig::Permalink.find_by(full_path: "/#{params[:id]}".squeeze('/')).try(:resource)
        @content_package = scope.find(params[:id]) if @content_package.nil?
        @content_package
      end

      def get_view_data
        @persona_groups = Pig::PersonaGroup.all.includes(:personas)
        @activity_items = @content_package.activity_items.includes(:user, :resource).paginate(:page => 1, :per_page => 5)
        @non_meta_content_attributes = @content_package.content_attributes.where(:meta => false)
        @meta_content_attributes = @content_package.content_attributes.where(:meta => true)
        @changes_tab = params[:compare1] ? true : false
      end

      def update_content_package
        # Because of the way pig uses method missing to update each content chunk just using
        # touch: true on the association would result in an update on the content package for every chunk
        # Because of this the updated_at time is set here

        previous_status = @content_package.status

        @content_package.last_edited_by = current_user
        content_package_params[:author_id]=current_user.id if content_package_params[:author_id].nil? || content_package_params[:author_id].empty?
                
        #If permalink changed, don't pass the parameter to update_attributes but update aliases here
        if @content_package.permalink && !content_package_params[:permalink_path].nil? && (content_package_params[:permalink_path] != @content_package.permalink.path)

          new_permalink_path = content_package_params[:permalink_path]
          old_permalink =  @content_package.permalinks.active.first

          # Put the params back to how they were
          content_package_params[:permalink_path] = @content_package.permalink.path

          # Disable the old permalink
          old_permalink.update_attribute(:active, false)

          # Save new permalink (or update an old version of it)
          if @content_package.parent
            new_permalink_full_path = @content_package.parent.permalink_display_path.chop + "/" + new_permalink_path
          else
            new_permalink_full_path = "/" + new_permalink_path
          end
          new_permalink = Permalink.find_or_initialize_by(full_path: new_permalink_full_path)
          new_permalink.update_attributes(path: new_permalink_path, 
            resource_id: @content_package.id, 
            resource_type: "Pig::ContentPackage", 
            active: true, 
            full_path:  new_permalink_full_path)
        end


        if @content_package.update_attributes(content_package_params)
          flash[:notice] = "Updated \"#{@content_package}\""
          if @content_package.status == 'published' && previous_status != 'published'
            @content_package.published_at = DateTime.now
            @content_package.save
          end
          if params[:view]
            redirect_to pig.content_package_path(@content_package)
          elsif params[:preview]
            redirect_to pig.preview_admin_content_package_path(@content_package)
          else
            redirect_to pig.edit_admin_content_package_path(@content_package)
          end
        else
          #TODO change to flash[:error] when the style has been made
          flash[:notice] = "Sorry there was a problem saving this page: #{@content_package.errors.full_messages.to_sentence}"
          render :action => 'edit'
        end
      end

      def set_editing_user
        @content_package.editing_user = current_user
        @content_package.last_edited_by = current_user
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
end
