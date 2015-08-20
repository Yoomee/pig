require 'rails_helper'

module Pig
  RSpec.describe Admin::PersonasController, type: :controller do
    routes { Pig::Engine.routes }

    context "not signed in" do
      requests = ['index']

      let(:index) { get :index }

      requests.each do |request|
        it "should redirect #{request} to sign in" do
          eval(request)
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context "signed in" do
      login_admin
      describe "GET #index" do
        it "returns http success" do
          get :index
          expect(response).to have_http_status(:success)
        end
      end
    end

  end
end
