# frozen_string_literal: true

module ClaimsApi
  module BGSClient
    module ServiceAction
      Definition =
        Data.define(
          :service_path,
          :service_namespaces,
          :action_name
        )

      module Definition::ManageRepresentativeService
        service_definition = {
          service_path: 'VDC/ManageRepresentativeService',
          service_namespaces: { 'data' => '/data' }
        }

        ReadPoaRequest =
          Definition.new(
            action_name: 'readPOARequest',
            **service_definition
          )
      end
    end
  end
end
