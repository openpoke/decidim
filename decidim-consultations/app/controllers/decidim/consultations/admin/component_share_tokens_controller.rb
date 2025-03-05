# frozen_string_literal: true

module Decidim
  module Consultations
    module Admin
      class ComponentShareTokensController < Decidim::Admin::ShareTokensController
        include ConsultationAdmin

        helper_method :current_participatory_space

        def resource
          @resource ||= current_question.components.find(params[:component_id])
        end
      end
    end
  end
end
