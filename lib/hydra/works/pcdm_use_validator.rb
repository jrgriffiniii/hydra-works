module Hydra::Works
  class PcdmUseValidator
    # Provide class method, because that's what ActiveFedora will be looking
    # for.
    def self.validate!(_association, file_set)
      # But.. immediately instantiate the class so we can hold state, and use
      # cleaner instance methods.
      # TODO: Why do we use this pattern?
      new(file_set).validate!
    end

    attr_reader :file_set

    def initialize(file_set)
      @file_set = file_set
    end

    def validate!
      raise InvalidPcdmUse unless invalid_pcdm_uses.empty?
      raise MissingRequiredPcdmUse unless required_but_missing_pcdm_uses.empty?
      raise DuplicatePcdmUseNotAllowed unless unallowed_duplicate_pcdm_uses.emtpy?
    end

    # TODO: Are there better error classes from AF (or elsewhere) to use/extend here?
    # TODO: Add informative error messages, complete with helpful suggestions.
    # TODO: Ok to namespace these error under Hydra::Works::PcdmUseValidator class?
    class InvalidPcdmUse < StandardError; end
    class MissingPcdmUse < StandardError; end
    class DuplicatePcdmUse < StandardError; end

    private

      # Returns a list of pcdm:use values from the file set's files that
      # aren't in the list of allowed values for pcdm:use.
      def invalid_pcdm_uses
        pcdm_uses - allowed_pcdm_uses
      end

      # Returns a list of pcdm:use values that are required, but missing from
      # the file set's files.
      def required_but_missing_pcdm_uses
        required_pcdm_uses - pcdm_uses
      end

      # Return a list of pcdm:use values that are specified as required in the
      # config.
      def required_pcdm_uses
        config.select do |_pcdm_use, options|
          options[:required]
        end.keys
      end

      # Returns a list of all pcdm:use values from the file set's files that
      # exist more than once, but are not allowed to exist more than once.
      def unallowed_duplicate_pcdm_uses
        duplicate_pcdm_uses - pcdm_uses_limited_to_one
      end

      # Returns a list of pcdm:use values from the file set's files that occur
      # more than once.
      def duplicate_pcdm_uses
        count = Hash.new 0
        pcdm_uses.each { |pcdm_use| count[pcdm_use] += 1 }
        count.keys
      end

      # Returns a list of pcdm:uses that are limited to one according to the
      # config.
      def pcdm_uses_limited_to_one
        config.select do |_pcdm_use, options|
          !options[:multiple]
        end
      end

      # Returns a list of all pdcm:use values from the file set's files.
      def pcdm_uses
        file_set.files.map(&:type)
      end

      # Returns a list of allowed pdcm:use values.
      # This requires querying QuestioningAuthority, so it's memoized.
      def allowed_pcdm_uses
        @allowed_pcdm_uses ||= begin
          # Use QuestioningAuthority to retrieve available option. The way
          # this validation code is written above, this should be a list of
          # values that are comparable to the return value of PCDM::File#type.
          # AFAIK, QA gives you URLs that you can query to return JSON, but
          # there might be amore efficient way using the ruby object directly.
          # In any event, to make the values comparable, you'd probably have
          # to map them to something other than what QA gives you.
        end
      end

      # Returns a config hash parsed from a YAML file.
      # This requires I/O, so it's memoized
      def config
        @config ||= YAML.safe_load(config_path)
      end

      # Returns the first config file found among the optional locations.
      def config_path
        optional_config_paths.each { |p| return p if File.exist?(p) }
      end

      # Returns a list of optional locations for the config file, ordered
      # from most specific, to most generic.
      # TODO: Is this an intuitive convention for the config file name and location?
      def optional_config_paths
        @optional_config_paths ||= [
          # Check for pcdm_use.yml first in the host app's root.
          "#{Rails.root}/config/pcdm_use_validator.yml",

          # Next, use the default pcdm_use.yml that ships with Hydra-Works
          "#{Hydra::Works.root}/config/pcdm_use_validator.yml"
        ]
      end
  end
end
