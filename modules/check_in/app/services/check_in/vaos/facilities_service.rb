module CheckIn
  module VAOS
    class FacilitiesService
      def initialize
        @service = ::VAOS::V2::MobileFacilityService.new
      end

      def get_facilities(ids:, schedulable:, children: nil, type: nil, pagination_params: {})
        @service.get_facilities(ids:, schedulable:, children:, type:,
                                pagination_params:)
      end

      def get_facilities_with_cache(*ids)
        @service.get_facilities_with_cache(*ids)
      end

      def get_facility(facility_id)
        @service.get_facility(facility_id)
      end

      def get_facility_with_cache(facility_id)
        @service.get_facility_with_cache(facility_id)
      end
    end
  end
end
