# frozen_string_literal: true

namespace :tasks do
  namespace :import do
    desc "Usage: rake tasks:import:geojson FILE='<filename.geojson>' ORG_ID=<organization_id> VERBOSE='true' FORCE_EXT_TO='.json' SCOPE_TYPE='municipality'"
    task geojson: :environment do
      @importer = Decidim::Importers::Geojson.new(
        default_values: { hex_color: "#157173", scope_type: "municipality" },
        log_filename: "import-geojson"
      )

      @importer.execute
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
