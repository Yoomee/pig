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
        render :json => Pig::ContentPackage.pig_search(term).includes(:permalink).map { |cp| {
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
        puts "DEBUG: entered update"
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
        puts "DEBUG: entered get_view_data"
        @persona_groups = Pig::PersonaGroup.all.includes(:personas)
        @activity_items = @content_package.activity_items.includes(:user, :resource).paginate(:page => 1, :per_page => 5)
        @non_meta_content_attributes = @content_package.content_attributes.where(:meta => false)
        @meta_content_attributes = @content_package.content_attributes.where(:meta => true)
        @changes_tab = params[:compare1] ? true : false
        @analytics_data = analytics_data(@content_package)
      end

      def get_ga_page_path
        @content_package.permalink_full_path.nil? ? "/" :  @content_package.permalink_full_path 
      end

      def update_content_package
        puts "DEBUG: entered update_content_package"

        # Because of the way pig uses method missing to update each content chunk just using
        # touch: true on the association would result in an update on the content package for every chunk
        # Because of this the updated_at time is set here

        previous_status = @content_package.status

        @content_package.last_edited_by = current_user
        content_package_params[:author_id]=current_user.id if content_package_params[:author_id].nil? || content_package_params[:author_id].empty?
                
        #If permalink changed, don't pass the parameter to update attributes but update aliases here
        if @content_package.permalink && !content_package_params[:permalink_path].nil? && (content_package_params[:permalink_path] != @content_package.permalink.path)

          puts "DEBUG: A"

          new_permalink_path = content_package_params[:permalink_path]
          old_permalink =  @content_package.permalinks.active.first

          # Put the params back to how they were
          content_package_params[:permalink_path] = @content_package.permalink.path

          # Disable the old permalink
          old_permalink.update_attribute(:active, false)

          # Save new permalink (or update an old version of it)
          if @content_package.parent
            puts "DEBUG: B"
            new_permalink_full_path = @content_package.parent.permalink_display_path.chop + "/" + new_permalink_path
          else
            puts "DEBUG: C"
            new_permalink_full_path = "/" + new_permalink_path
          end
          new_permalink = Permalink.find_or_initialize_by(full_path: new_permalink_full_path)
          new_permalink.update(path: new_permalink_path, 
            resource_id: @content_package.id, 
            resource_type: "Pig::ContentPackage", 
            active: true, 
            full_path:  new_permalink_full_path)
        end

        puts "DEBUG: Attributes before update: #{@content_package.attributes.inspect}"
        puts "DEBUG: Attributes to update: #{content_package_params.inspect}"

        if @content_package.changed?
          puts "DEBUG: Changes detected: #{@content_package.changes.inspect}"
        else
          puts "DEBUG: No changes detected."
        end

        puts "DEBUG: Current parent_id: #{@content_package.parent_id}"
        puts "DEBUG: New parent_id: #{content_package_params[:parent_id]}"

        if @content_package.update(content_package_params)
          puts "DEBUG: D"
          flash[:notice] = "Updated \"#{@content_package}\""
          if @content_package.status == 'published' && previous_status != 'published'
            @content_package.published_at = DateTime.now
            @content_package.save
          end
          if params[:view]
            puts "DEBUG: E"
            redirect_to pig.content_package_path(@content_package)
          elsif params[:preview]
            puts "DEBUG: F"
            redirect_to pig.preview_admin_content_package_path(@content_package)
          else
            puts "DEBUG: G"
            redirect_to pig.edit_admin_content_package_path(@content_package)
          end
        else
          #TODO change to flash[:error] when the style has been made
          puts "DEBUG: H"
          flash[:notice] = "Sorry there was a problem saving this page: #{@content_package.errors.full_messages.to_sentence}"
          render :action => 'edit'
        end
      end

      def set_editing_user
        @content_package.editing_user = current_user
        @content_package.last_edited_by = current_user
      end

      def analytics_data(page)
        cache_key = "analytics_data_#{@content_package.id}_#{Date.today}"
        Rails.cache.fetch(cache_key, expires_in: 2.hours) do

          ## Read app credentials from a file
          opts = YAML.load_file("ga_config.yml")
          view_id = "ga:#{opts['view_id']}"

          # Create a Google Analytics Reporting service
          service = Google::Apis::AnalyticsreportingV4::AnalyticsReportingService.new

          # Create service account credentials
          credentials = Google::Auth::ServiceAccountCredentials.make_creds(
            scope: 'https://www.googleapis.com/auth/analytics.readonly'
          )

          # Authorize with our readonly credentials
          service.authorization = credentials
          $google_client = service

          page_path = get_ga_page_path
          today=Date.today
          page_analytics = []

          # Call Google Analytics API for yesterday
          start_date = "yesterday"
          end_date = "today"
          page_analytics << ["Yesterday", get_analytics_data(view_id, page_path, start_date, end_date)]

          # Call Google Analytics API for 7 days ago
          start_date = "7daysAgo"
          end_date = "today"
          page_analytics << ["Last 7 days", get_analytics_data(view_id, page_path, start_date, end_date)]

          # Call Google Analytics API for last month
          start_date = today - 30
          page_analytics << ["Last month", get_analytics_data(view_id, page_path, start_date, end_date)]

          # Call Google Analytics API for last year
          start_date = today - 365
          page_analytics << ["Last year", get_analytics_data(view_id, page_path, start_date, end_date)]

          # Store debug info
          page_analytics << ["Debug info", [Time.now.utc, get_ga_page_path]]

        end
      end

      def  get_analytics_data(view_id, page_path, start_date, end_date)

        # Set the date range - this is always required for report requests
        date_range = Google::Apis::AnalyticsreportingV4::DateRange.new(
          start_date: "#{start_date}",
          end_date: "#{end_date}"
        )
        # Set the metrics
        page_views =  Google::Apis::AnalyticsreportingV4::Metric.new(expression: 'ga:uniquePageviews')
        avg_time_on_page =  Google::Apis::AnalyticsreportingV4::Metric.new(expression: 'ga:avgTimeOnPage')
        exits =  Google::Apis::AnalyticsreportingV4::Metric.new(expression: 'ga:exits')

        # Set the dimension
        dimension = Google::Apis::AnalyticsreportingV4::Dimension.new(
            name: 'ga:pagePath'
          )

        # Build up our report request and a add country filter
        report_request = Google::Apis::AnalyticsreportingV4::ReportRequest.new(
          view_id: "#{view_id}",
          filters_expression: "ga:PagePath==#{page_path}",
          date_ranges: [date_range],
          metrics: [page_views, avg_time_on_page, exits],
          dimensions: [dimension]
        )

        # Skip creating a new report TODO
        return []

        # Create a new report request
        request = Google::Apis::AnalyticsreportingV4::GetReportsRequest.new( report_requests: [report_request] )
        # Make API call.
        response = $google_client.batch_get_reports(request)
        return response.reports.last.data.totals[0].values
      end

    end
  end
end
