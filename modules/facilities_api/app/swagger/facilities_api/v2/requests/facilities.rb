# frozen_string_literal: true

module FacilitiesApi
  class V2::Requests::Facilities
    include Swagger::Blocks
    # rubocop:disable Layout/LineLength
    swagger_path '/facilities_api/v2/va' do
      operation :post do
        key :description, 'Get facilities within a geographic bounding box'
        key :operationId, 'searchFacilities'
        key :tags, %w[facilities]

        parameter do
          key :name, :bbox
          key :description, 'Optional bounding box Lat/Long coordinates in the form minLong, minLat, maxLong, maxLat'
          key :in, :body
          key :required, false
          schema do
            key :$ref, :BboxInput
          end
        end
        parameter do
          key :name, :type
          key :description, 'Optional facility type'
          key :in, :body
          key :required, false
          schema do
            key :$ref, :TypeInput
          end
        end
        parameter do
          key :name, :services
          key :description, 'Optional specialty services filter that works along with `type` param. Only available for types \'benefits\' and \'vet_center\'.'
          key :in, :body
          schema do
            key :$ref, :ServicesInput
          end
        end

        response 200 do
          key :description, 'Successful bounding box query'
          schema do
            key :$ref, :Facilities
          end
        end
        response 400 do
          key :description, 'Invalid bounding box query'
          schema do
            key :$ref, :Errors
          end
        end
      end
    end

    # rubocop:enable Layout/LineLength
    swagger_path '/facilities_api/v2/va/{id}' do
      operation :get do
        key :description, 'Get an individual facility detail object'
        key :operationId, 'showFacility'
        key :tags, %w[facilities]

        parameter do
          key :name, :id
          key :description, 'ID of facility such as vha_648A4'
          key :in, :path
          key :type, :string
          key :required, true
        end

        response 200 do
          key :description, 'Successful facility detail lookup'
          schema do
            key :$ref, :Facility
          end
        end
        response 404 do
          key :description, 'Non-existent facility lookup'
          schema do
            key :$ref, :Errors
          end
        end
      end
    end

    # rubocop:disable Layout/LineLength
    [
      'urgent_care', 'an Urgent Care facilities',
      'provider', 'a Provider',
      'pharmacy', 'a Pharmacy'
    ].each do |path, description|
      swagger_path "/facilities_api/v2/ccp/#{path}" do
        operation :get do
          key :description, "Get #{description} within a radius of the latitude/longitude"
          key :operationId, 'indexProviders'
          key :tags, %w[providers]

          parameter do
            key :name, :lat
            key :description, 'Latitude'
            key :in, :query
            key :type, :number
          end
          parameter do
            key :name, :latitude
            key :description, 'Latitude'
            key :in, :query
            key :type, :number
          end
          parameter do
            key :name, :long
            key :description, 'Longitude'
            key :in, :query
            key :type, :number
          end
          parameter do
            key :name, :longitude
            key :description, 'Longitude'
            key :in, :query
            key :type, :number
          end
          parameter do
            key :name, :radius
            key :description, 'Search Radius'
            key :in, :query
            key :type, :number
          end
          if path == 'provider'
            parameter do
              key :name, 'specialties[]'
              key :description, 'Optional specialty services filter that works along with `type` param. Only available for types \'provider\'.'
              key :in, :query
              key :type, :array
              key :collectionFormat, :multi
              items do
                key :type, :string
              end
            end
          end

          response 200 do
            key :description, 'Successful bounding box query'
            schema do
              key :$ref, :Provider
            end
          end
          response 400 do
            key :description, 'Invalid bounding box query'
            schema do
              key :$ref, :Errors
            end
          end
        end
      end
    end

    # rubocop:enable Layout/LineLength
    swagger_path '/facilities_api/v2/ccp/specialties' do
      operation :get do
        key :description, 'Get a list of all available specialties'
        key :operationId, 'showSpecialties'
        key :tags, %w[facilities]

        response 200 do
          key :description, 'Successful specialties lookup'
          schema do
            key :$ref, :Specialty
          end
        end
      end
    end

    swagger_schema :BboxInput do
      property :bbox do
        key :type, :array
        key :required, %i[minLong minLat maxLat maxLong]
        key :minItems, 4
        key :maxItems, 4
        items do
          key :type, :number
        end
      end
    end
    swagger_schema :TypeInput do
      property :type do
        key :type, :string
        key :enum, %w[health cemetery benefits vet_center]
      end
    end
    swagger_schema :ServicesInput do
      property :services do
        key :type, :array
        items do
          key :type, :string
        end
      end
    end
  end
end
