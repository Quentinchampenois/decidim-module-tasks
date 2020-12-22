# frozen_string_literal: true

namespace :tasks do
  namespace :import do
    desc "Usage: rake tasks:import:geojson FILE='<filename.geojson>' ORG_ID=<organization_id> VERBOSE='true' FORCE_EXT_TO='.json' SCOPE_TYPE='municipality'"
    task geojson: :environment do
      @importer = Decidim::Importers::Geojson.new(
        default_values: { hex_color: "#157173", scope_type: "municipality" },
        log_filename: "import-geojson"
      )

      @importer.display_help if @importer.configs[:file].blank?

      @importer.validations do
        @importer.validate_file(@importer.configs[:forced_file_extension].presence || ".geojson")
        @importer.validate_org
        @importer.validate_color
      end

      data = JSON.parse(File.read(@importer.configs[:file]))

      data["features"].each do |raw|
        Decidim::Scope.create! scope_params(raw)
      end
    rescue SystemExit,
           ActiveModel::UnknownAttributeError,
           ActiveRecord::RecordNotFound => e

      if @importer.blank?
        Rails.logger.fatal e
      else
        @importer.task_aborted_message(e)
      end
    end
  end
end

private

def scope_params(raw)
  scope_type = Decidim::ScopeType.where("name ->> 'en'= ?", @importer.configs[:scope_type].presence || @importer.default_values[:scope_type])&.first
  {
    name: { en: raw["properties"]["nom_comm"], fr: raw["properties"]["nom_comm"] },
    code: raw["properties"]["insee_comm"],
    scope_type: scope_type,
    organization: @importer.current_organization,
    parent: nil,
    geojson: {
      color: @importer.hex_color,
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
