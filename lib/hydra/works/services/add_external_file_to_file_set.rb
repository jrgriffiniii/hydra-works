module Hydra::Works
  class AddExternalFileToFileSet
    # Adds a file to the file_set
    # @param [Hydra::PCDM::FileSet] file_set the file will be added to
    # @param [String] external_file_url URL representing the externally stored file
    # @param [RDF::URI or String] type URI for the RDF.type that identifies the file's role within the file_set
    # @param [Hash] opts Options
    # @option opts [Boolean] :update_existing When set to true, performs a create_or_update. When set to false, always creates a new file within file_set.files.
    # @option opts [Boolean] :versioning Whether to create new version entries (only applicable if +type+ corresponds to a versionable file)
    # @option opts [String] :filename A string for the original file name. Defaults to the same value as external_file_url
    def self.call(file_set, external_file_url, type, opts = {})
      fail ArgumentError, 'supplied object must be a file set' unless file_set.file_set?

      update_existing = opts.fetch(:update_existing, true)
      versioning = opts.fetch(:versioning, true)
      filename = opts.fetch(:filename, external_file_url)

      # TODO: required as a workaround for https://github.com/samvera/active_fedora/pull/858
      file_set.save unless file_set.persisted?

      updater_class = versioning ? VersioningUpdater : Updater
      updater = updater_class.new(file_set, type, update_existing)
      status = updater.update(external_file_url, filename)
      status ? file_set : false
    end

    class Updater
      attr_reader :file_set, :current_file

      def initialize(file_set, type, update_existing)
        @file_set = file_set
        @current_file = find_or_create_file(type, update_existing)
      end

      # @param [#read] file object that will be interrogated using the methods: :path, :original_name, :original_filename, :mime_type, :content_type
      # None of the attribute description methods are required.
      def update(external_file_url, filename = nil)
        attach_attributes(external_file_url, filename)
        persist
      end

      private

        # Persist a new file with its containing file set; otherwise, just save the file itself
        def persist
          if current_file.new_record?
            file_set.save
          else
            current_file.save
          end
        end

        def attach_attributes(external_file_url, filename = nil)
          current_file.content = StringIO.new('')
          current_file.original_name = filename
          current_file.mime_type = "message/external-body; access-type=URL; URL=\"#{external_file_url}\""
        end

        # @param [Symbol, RDF::URI] the type of association or filter to use
        # @param [true, false] update_existing when true, try to retrieve existing element before building one
        def find_or_create_file(type, update_existing)
          if type.instance_of? Symbol
            find_or_create_file_for_symbol(type, update_existing)
          else
            find_or_create_file_for_rdf_uri(type, update_existing)
          end
        end

        def find_or_create_file_for_symbol(type, update_existing)
          association = file_set.association(type)
          fail ArgumentError, "you're attempting to add a file to a file_set using '#{type}' association but the file_set does not have an association called '#{type}''" unless association
          current_file = association.reader if update_existing
          current_file || association.build
        end

        def find_or_create_file_for_rdf_uri(type, update_existing)
          current_file = file_set.filter_files_by_type(type_to_uri(type)).first if update_existing
          unless current_file
            file_set.files.build
            current_file = file_set.files.last
            Hydra::PCDM::AddTypeToFile.call(current_file, type_to_uri(type))
          end
          current_file
        end

        # Returns appropriate URI for the requested type
        #  * Converts supported symbols to corresponding URIs
        #  * Converts URI strings to RDF::URI
        #  * Returns RDF::URI objects as-is
        def type_to_uri(type)
          case type
          when ::RDF::URI
            type
          when String
            ::RDF::URI(type)
          else
            fail ArgumentError, 'Invalid file type.  You must submit a URI or a symbol.'
          end
        end
    end

    class VersioningUpdater < Updater
      def update(*)
        super && current_file.create_version
      end
    end
  end
end
