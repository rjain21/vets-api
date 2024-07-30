# frozen_string_literal: true

module Pensions
  class Engine < ::Rails::Engine
    isolate_namespace Pensions
    config.generators.api_only = true

    initializer 'model_core.factories', after: 'factory_bot.set_factory_paths' do
      FactoryBot.definition_file_paths << File.expand_path('../../spec/factories', __dir__) if defined?(FactoryBot)
    end

    initializer 'pensions.after_initialize' do |app|
      app.config.after_initialize do
        # Register our Pension Pdf Fill form
        PdfFill::Filler.register_form(PdfFill::Forms::Va21p527ez::FORM_ID, PdfFill::Forms::Va21p527ez)
      end
    end
  end
end
