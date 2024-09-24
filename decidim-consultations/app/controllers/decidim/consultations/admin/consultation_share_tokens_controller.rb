# frozen_string_literal: true

module Decidim
  module Consultations
    module Admin
      class ConsultationShareTokensController < Decidim::Admin::ShareTokensController
        include ConsultationAdmin

        helper_method :current_participatory_space

        def resource
          current_consultation
        end
      end
    end
  end
end
