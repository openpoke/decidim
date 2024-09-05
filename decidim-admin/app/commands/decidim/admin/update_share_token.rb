# frozen_string_literal: true

module Decidim
  module Admin
    # A command with all the business logic to update a share token.
    # This command is called from the controller.
    class UpdateShareToken < Decidim::Command
      # Public: Initializes the command.
      #
      # form - A form object with the params.
      # token - The ShareToken object to update.
      def initialize(form, token)
        @form = form
        @token = token
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if form.invalid?

        update_share_token
        broadcast(:ok)
      end

      private

      attr_reader :form, :token

      def update_share_token
        Decidim.traceability.update!(
          token,
          form.user,
          {
            expires_at: form.expires_at,
            token_for: form.token_for,
            registered_only: form.registered_only,
            organization: form.organization,
            user: form.user
          }
        )
      end
    end
  end
end
