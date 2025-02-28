# frozen_string_literal: true

module Decidim
  module Map
    module Provider
      module StaticMap
        # The static map utility class for the HERE maps service
        class Here < ::Decidim::Map::StaticMap
          # @See Decidim::Map::StaticMap#url_params
          def url_params(latitude:, longitude:, options: {})
            params = {
              c: "#{latitude}, #{longitude}",
              z: options[:zoom] || 15,
              w: options[:width] || 120,
              h: options[:height] || 120,
              f: 1
            }

            params[:apiKey] = configuration[:api_key]

            params
          end
        end
      end
    end
  end
end
