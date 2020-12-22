# frozen_string_literal: true

module Decidim
  module Importers
    class Import
      @logger = Rails.logger

      def initialize(test, org_id:, disable_validations: false)
        @test = test
        @org_id = org_id.strip
        @disable_validations = disable_validations
      end

      def configs
        raise NotImplementedError
      end

      def validations
        raise NotImplementedError if !block_given? && !@disable_validations

        yield
      end

      def display_help(help_message)
        puts help_message # Documentation should be printed on stdout even if verbose mode is disabled
        @logger.info help_message unless verbose?
        exit 0
      end

      def task_aborted_message(err)
        return "Rake task aborted" if err.blank?

        "Unexpected error occured:
> Error : #{err}

Rake task aborted
"
      end

      def verbose?
        @verbose ||= configs[:verbose].present? && (configs[:verbose] == "true" || configs[:verbose] == "1")
      end

      def org_id
        return if @org_id.blank?

        @org_id.to_i if /\A\d+\z/.match? @org_id
      end
    end
  end
end
