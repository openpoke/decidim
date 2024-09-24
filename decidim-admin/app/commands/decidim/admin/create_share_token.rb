# frozen_string_literal: true

module Decidim
  module Admin
    # A command with all the business logic to create a taxonomy.
    # This command is called from the controller.
    class CreateShareToken < Decidim::Command
      # Public: Initializes the command.
      #
      # form - A form object with the params.
      def initialize(form)
        @form = form
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if form.invalid?

        new_token = create_share_token
        broadcast(:ok, new_token)
      end

      private

      attr_reader :form

      def create_share_token
        Decidim.traceability.create!(
          ShareToken,
          form.user,
          {
            token: form.token,
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
