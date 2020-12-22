# frozen_string_literal: true

namespace :tasks do
  @logger = Rails.logger

  namespace :import do
    desc "Usage: rake tasks:import:geojson FILE='<filename.geojson>' ORG=<organization_id> [VERBOSE=true]"
    task geojson: :environment do
      configs = {
        verbose: ENV["VERBOSE"],
        file: ENV["FILE"],
        organization_id: ENV["ORGANIZATION_ID"],
        scope_type: ENV["SCOPE_TYPE"],
        forced_file_extension: ENV["FORCE_EXT_TO"]
      }

      @verbose_mode = configs[:verbose].present? && configs[:verbose] == "true"
      @logger = logger_output
      display_help if configs[:file].blank?

      @file = configs[:file]
      validate_file(configs[:forced_file_extension].presence || ".geojson")

      data = JSON.parse(File.read(@file))

      data["features"].each do |raw|
        Decidim::Scope.create!(
          name: { "en" => raw["properties"]["nom_comm"], "fr" => raw["properties"]["nom_comm"] },
          code: raw["properties"]["insee_comm"],
          scope_type: Decidim::ScopeType.where("name ->> 'en'= ?", "municipality").first,
          organization: Decidim::Organization.first,
          parent: nil,
          geojson: {
            color: "#157173",
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
        )
      end
    rescue SystemExit, ActiveModel::UnknownAttributeError => e
      @logger.fatal task_aborted_message(e) unless @verbose_mode

      # puts task_aborted_message(e)

      # data["features"][0].keys
      # Count : 1238
      # => "type" : String
      # "geometry" : Hash
      #   - type : String
      #   - coordinates : String
      # "properties" : Hash
      #   - st_length_shape : String
      #   - insee_comm : String
      #   - geo_point_2d : String
      #   - nom_comm : String
      #   - st_area_shape : String
      #   - epci : String
      #   - insee_dep : String
    end
  end
end

private

def logger_output(base_name = "import-geojson")
  return Logger.new("log/#{base_name}-#{Time.zone.now.strftime "%Y-%m-%d-%H:%M:%S"}.log") unless @verbose_mode

  Logger.new(STDOUT)
end

def validate_input
  validate_file
  validate_process
  validate_admin
  validate_org
end

def validate_org
  if @org.class != Integer
    puts "You must pass an organization id as an integer"
    exit 1
  end

  unless current_organization
    puts "Organization does not exist"
    exit 1
  end
end

def validate_file(extension = ".csv")
  unless File.exist?(@file)
    puts "File does not exist, be sure to pass a full path."
    exit 1
  end

  if extension == ".csv" && File.extname(@file) != ".csv"
    puts "You must pass a CSV file"
    exit 1
  elsif extension == ".geojson" && File.extname(@file) != ".geojson"
    puts "You must pass a GEOJSON file"
    exit 1
  elsif extension != File.extname(@file)
    puts "File extension has been forced to '#{extension}' but does not match current file extension '#{File.extname(@file)}' "
    exit 1
  end
end

def display_help
  here_doc = <<~HEREDOC
    Help:
    :: Import Geojson ::
    >  Usage: rake import:geojson FILE='<filename.geojson>' ORG=<organization_id>
  HEREDOC

  @logger.info here_doc unless @verbose_mode
  exit 0
end

def check_csv(file)
  file.each do |row|
    # Check if id, first_name, last_name are nil
    next unless row[0].nil? || row[1].nil? || row[2].nil?

    puts "Something went wrong, empty field(s) on line #{$INPUT_LINE_NUMBER}"
    puts row.inspect
    exit 1
  end
end

def set_name(first_name, last_name)
  first_name + " " + last_name
end

def current_user
  @current_user ||= Decidim::User.find(@admin)
end

def current_organization
  @current_organization ||= Decidim::Organization.find(@org)
end

def current_process
  @current_process ||= Decidim::ParticipatoryProcess.find(@process)
end

def task_aborted_message(err)
  return "Rake task aborted" if err.blank?

  "Unexpected error occured:
> Error : #{err}

Rake task aborted
"
end
