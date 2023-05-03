module Pig
  class ContentPackageMailer < ActionMailer::Base
    helper Pig::UrlHelper

    default from: Settings.site_noreply_email

    def assigned_for_review(content_package, assigned_to)
      # send_assigned_email(content_package, assigned_to) // Switched off email
    end

    def assigned_for_writing(content_package, assigned_to)
      #send_assigned_email(content_package, assigned_to) // Switched off email
    end

    def assigned_for_updating(content_package, assigned_to)
      #send_assigned_email(content_package, assigned_to) // Switched off email
    end

    def published(content_package, last_edited_by)
      @content_package = content_package
      @user = last_edited_by
      mail(to: last_edited_by.email,
           subject: default_i18n_subject(
             site_name: Settings.site_name,
             content_package_name: content_package.name
           ))
    end

    def getting_old(user, content_packages)
      @content_packages = content_packages
      @user = user
      title = if @content_packages.count > 1
                "#{@content_packages.count} content packages are "
              else
                "#{@content_packages.first.name} is"
              end
      mail(to: @user.email,
           subject: default_i18n_subject(
             site_name: Settings.site_name,
             title: title
           ))
    end

    private

    def send_assigned_email(content_package, to)
      @content_package = content_package
      @user = to
      mail(to: to.email,
           subject: default_i18n_subject(
             site_name: Settings.site_name,
             content_package_name: content_package.name
           ))
    end
  end
end
