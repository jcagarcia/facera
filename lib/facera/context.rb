module Facera
  # Lightweight context object for block evaluation
  # Replaces OpenStruct with a simpler, faster implementation
  class Context
    def initialize(data = {})
      @data = data.transform_keys(&:to_sym)
    end

    def method_missing(method, *args)
      if args.empty?
        # Getter
        @data[method]
      elsif method.to_s.end_with?('=')
        # Setter
        @data[method.to_s.chomp('=').to_sym] = args.first
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      @data.key?(method) || method.to_s.end_with?('=') || super
    end

    def to_h
      @data
    end
  end
end
