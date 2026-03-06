require_relative "facera/version"
require_relative "facera/registry"
require_relative "facera/attribute"
require_relative "facera/entity"
require_relative "facera/invariant"
require_relative "facera/capability"
require_relative "facera/core"
require_relative "facera/errors"
require_relative "facera/error_formatter"
require_relative "facera/field_visibility"
require_relative "facera/capability_access"
require_relative "facera/facet"
require_relative "facera/dsl"

module Facera
  class Error < StandardError; end
end
