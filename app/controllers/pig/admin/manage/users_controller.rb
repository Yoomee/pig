module Pig
  module Admin
    module Manage
      class UsersController < Pig::Admin::ApplicationController

        load_and_authorize_resource class: 'Pig::User'

        def set_active
          @user.update(active: !@user.active)
          @show_inactive = session[:show_inactive] || false
          redirect_to pig.admin_manage_users_path(params)
        end

        def index
          @show_inactive = (params[:show_inactive] && params[:show_inactive] == "true") || false
          if @show_inactive
            @users = Pig::User.all_users
          else
            @users = Pig::User.all_users.where(active: true)
          end
          @users = @users.order('LOWER(last_name)')
          session[:show_inactive] = @show_inactive
        end

        def destroy
          # Cast back to user so we don't break all the callbacks
          @user_id = @user.id
          @user.destroy
        end

        def show
          @assigned_content = Pig::ContentPackage.where(author_id: @user.id)
        end

        def edit
        end

        def update
          if @user.update_attributes(user_params)
            sign_in(@user, bypass: true) if @user == current_user
            redirect_to pig.admin_manage_user_path(@user)
          else
            render :action => "edit"
          end
        end

        def create
          if @user.save
            redirect_to(pig.admin_manage_user_path(@user))
          else
            render :action => "new"
          end
        end

        def new
        end

        def content
          render json: @user.assigned_content_packages.to_json
        end

        def deactivate
          (params[:content_package] || []).each do |cp_id, u_id|
            Pig::ContentPackage.find(cp_id).update_attribute(:author_id, u_id)
          end
          @user.update_attribute(:active, false)
          redirect_to pig.admin_manage_users_path, notice: 'User deactivated'
        end

        private

          def user_params
            if params[:user][:password].blank? || params[:user][:password_confirmation].blank?
              params[:user].delete(:password)
              params[:user].delete(:password_confirmation)
            end
            params.require(:user).permit(permitted_user_parameters.push(:password, :password_confirmation))
          end

          def permitted_user_parameters
            permitted_params = %w(bio email first_name image last_name remove_image retained_image active)
            if can?(:alter_role, @user)
              req_role = params[:user][:role]
              if req_role.present? && req_role.to_sym.in?(current_user.available_roles)
                permitted_params << 'role'
              end
            end
            permitted_params
          end
      end
    end
  end
end
