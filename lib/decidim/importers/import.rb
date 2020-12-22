# frozen_string_literal: true

module Decidim
  module Importers
    class Import
      attr_accessor :logger

      def initialize(log_filename:, disable_validations: false)
        @log_filename = logger_filename
        @disable_validations = disable_validations
      end

      def configs
        raise NotImplementedError
      end

      def logger_filename(filename = "importer")
        return filename if filename.present?

        "importer"
      end

      def validations
        raise NotImplementedError if !block_given? && !@disable_validations

        yield
      end

      def display_help
        raise NotImplementedError

        # Example
        # puts @help_msg # Documentation should be printed on stdout even if verbose mode is disabled
        # @logger.info @help_msg unless verbose?
        # exit 0
      end

      def task_aborted_message(err)
        @logger.error("Rake task aborted") if err.blank?

        @logger.error("Unexpected error occured:
> Error : #{err}

Rake task aborted
")
      end

      def verbose?
        @verbose ||= configs[:verbose].present? && (configs[:verbose] == "true" || configs[:verbose] == "1")
      end

      def set_logger
        return Logger.new(STDOUT) if verbose?

        Logger.new("log/#{@log_filename}-#{Time.zone.now.strftime "%Y-%m-%d-%H:%M:%S"}.log")
      end
    end
  end
end
