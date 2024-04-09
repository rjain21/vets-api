# frozen_string_literal: true

class LHDIApplicationRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :lhdi_production, reading: :lhdi_production }
end
