# frozen_string_literal: true

module Decidim
  module Importers
    class Geojson < Import
      def initialize(default_values:, log_filename:, disable_validations: false)
        @default_values = default_values
        @log_filename = log_filename
        @disable_validations = disable_validations
        @logger = set_logger
        configs
      end

      def execute
        display_help

        validations do
          validate_file(configs[:forced_file_extension].presence || ".geojson")
          validate_org
          validate_color
        end

        data = JSON.parse(File.read(configs[:file]))
        data["features"]&.each do |raw|
          Decidim::Scope.create! params(raw)
        end
      end

      private

      def configs
        @configs ||= {
          verbose: ENV["VERBOSE"]&.strip,
          file: ENV["FILE"]&.strip,
          organization_id: org_id,
          scope_type: ENV["SCOPE_TYPE"]&.strip,
          forced_file_extension: ENV["FORCE_EXT_TO"]&.strip,
          color: hex_color
        }
      end

      def org_id
        return if ENV["ORG_ID"].blank?

        ENV["ORG_ID"].strip.to_i if /\A\d+\z/.match? ENV["ORG_ID"].strip
      end

      def hex_color
        return ENV["COLOR"].strip if ENV["COLOR"].present?

        @default_values[:hex_color]
      end

      def current_organization
        return if configs[:organization_id].blank?

        @current_organization ||= Decidim::Organization.find(configs[:organization_id])
      end

      def validate_org
        unless configs[:organization_id].is_a? Integer
          @logger.error "You must pass an organization id as an integer"
          exit 1
        end

        unless current_organization
          @logger.error "Organization does not exist"
          exit 1
        end
      end

      def validate_color
        unless /^#([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$/.match? configs[:color]
          @logger.error "You must pass a color as hexadecimal
Example: #FFFFFF
If you don't specify color, default color will be '#{@default_values[:hex_color]}'
"
          exit 1
        end
      end

      def validate_file(extension = ".csv")
        unless File.exist? @configs[:file]
          @logger.error "File does not exist, be sure to pass a full path."
          exit 1
        end

        if extension == ".csv" && File.extname(@configs[:file]) != ".csv"
          @logger.error "You must pass a CSV file"
          exit 1
        elsif extension == ".geojson" && File.extname(@configs[:file]) != ".geojson"
          @logger.error "You must pass a GEOJSON file"
          exit 1
        elsif extension != File.extname(@configs[:file])
          @logger.error "File extension has been forced to '#{extension}' but does not match current file extension '#{File.extname(@configs[:file])}' "
          exit 1
        end
      end

      def display_help
        return if configs[:file].present?

        here_doc = <<~HEREDOC
          Help:
          :: Import Geojson ::
          >  Usage: rake import:geojson FILE='<filename.geojson>' ORG_ID=<organization_id> VERBOSE='true' FORCE_EXT_TO='.json' SCOPE_TYPE='municipality'
           OPTIONAL PARAMETERS :
           ORG_ID - String : Decidim organization ID
           VERBOSE - String : Allows to output to stdout, if not 'true', writes logs in file
           FORCE_EXT_TO - String : Allows to force file extension validation. You must begins the value with a dot
           SCOPE_TYPE - String : Name of the Decidim Scope Type, by default '#{@default_values[:scope_type]}'
           COLOR - String : Allows to define color on map. You must pass hexadecimal value only. Default to '#{@default_values[:hex_color]}'

        HEREDOC

        puts here_doc # Documentation should be printed on stdout even if verbose mode is disabled
        @logger.info here_doc unless verbose?
        exit 0
      end

      def params(raw)
        scope_type = Decidim::ScopeType.where("name ->> 'en'= ?", configs[:scope_type].presence || @default_values[:scope_type])&.first
        {
          name: { en: raw["properties"]["nom_comm"], fr: raw["properties"]["nom_comm"] },
          code: raw["properties"]["insee_comm"],
          scope_type: scope_type,
          organization: current_organization,
          parent: nil,
          geojson: {
            color: hex_color,
            geometry: {
              "type": "Feature",
              "properties": raw["properties"],
              "formattedProperties": raw["properties"],
              "geometry": raw["geometry"]
            },
            parsed_geometry: {
              "type": "Feature",
              "properties": raw["properties"],
              "formattedProperties": raw["properties"],
              "geometry": raw["geometry"]
            }
          }
        }
      end
    end
  end
end
