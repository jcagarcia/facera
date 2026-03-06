#!/usr/bin/env rackup
# Facera Multi-Facet Payment API
# Run: rackup -p 9292

require_relative '../../lib/facera'
require_relative 'config/facera'
require_relative 'application'

# Run the application
run PaymentAPI::Application.build
