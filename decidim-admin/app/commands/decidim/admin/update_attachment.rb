# frozen_string_literal: true

module Decidim
  module Admin
    # A command with all the business logic to update an attachment from a
    # participatory process.
    class UpdateAttachment < Decidim::Command
      include ::Decidim::AttachmentAttributesMethods

      attr_reader :attachment

      delegate :current_user, to: :form
      # Public: Initializes the command.
      #
      # attachment - the Attachment to update
      # form - A form object with the params.
      def initialize(attachment, form)
        @attachment = attachment
        @form = form
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      # - :invalid if the form was not valid and we could not proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if form.invalid?

        update_attachment
        broadcast(:ok)
      end

      private

      attr_reader :form

      def update_attachment
        Decidim.traceability.update!(@attachment, current_user, attributes)
      end

      def attributes
        {
          title: form.title,
          file: form.file,
          link: form.link,
          description: form.description,
          weight: form.weight
        }.merge(
          attachment_attributes(:file)
        ).compact_blank.merge(
          attachment_collection: form.attachment_collection
        ).tap do |attrs|
          attrs[:file] = nil if form.link.present? && form.file.blank?
          attrs[:link] = nil if form.file.present? && form.link.blank?
        end
      end
    end
  end
end
