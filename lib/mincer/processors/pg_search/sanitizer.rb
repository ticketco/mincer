module Mincer
  module Processors
    module PgSearch
      class Sanitizer
        AVAILABLE_SANITIZERS = [:coalesce, :ignore_case, :ignore_accent]
        attr_accessor :term, :sanitizers

        def initialize(term, *sanitizers)
          @term, @sanitizers = term, AVAILABLE_SANITIZERS & Array.wrap(sanitizers).flatten
        end

        def sanitize_column
          @sanitized_column ||= sanitize(Arel.sql(@term))
        end

        def sanitize_string(options = {})
          if sanitizers.empty?
            return options[:quote] ? Mincer.connection.quote(@term) : @term
          end
          @sanitized_string ||= sanitize(@term)
        end

        def sanitize(node)
          sanitizers.inject(node) do |query, sanitizer|
            query = self.class.send(sanitizer, query)
            query
          end
        end

        def self.sanitize_column(term, *sanitizers)
          new(term, *sanitizers).sanitize_column
        end

        def self.sanitize_string(term, *sanitizers)
          new(term, *sanitizers).sanitize_string
        end

        def self.sanitize_string_quoted(term, *sanitizers)
          new(term, *sanitizers).sanitize_string(quote: true)
        end

        def self.ignore_case(term)
          Arel::Nodes::NamedFunction.new('lower', [term])
        end

        def self.ignore_accent(term)
          Arel::Nodes::NamedFunction.new('unaccent', [term])
        end

        def self.coalesce(term, val = '')
          if Mincer.pg_extension_installed?(:unaccent)
            Arel::Nodes::NamedFunction.new('coalesce', [term, val])
          else
            term
          end
        end

      end
    end
  end
end
