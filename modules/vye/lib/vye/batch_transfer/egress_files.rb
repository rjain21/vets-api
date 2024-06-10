# frozen_string_literal: true

module Vye
  module BatchTransfer
    module EgressFiles
      BDN_TIMEZONE = 'Central Time (US & Canada)'

      extend self

      private

      def credentials = Vye.settings.s3.to_h.slice(:region, :access_key_id, :secret_access_key)

      def bucket = Vye.settings.s3.bucket
      
      def external_bucket = Vye.settings.s3.external_bucket
      
      def s3_client = Aws::S3::Client.new(**credentials)

      def upload(file)
        key = "processed/#{file.basename.to_s}"
        body = file.open('rb')
        content_type = 'text/plain'

        s3_client.put_object(bucket:, key:, body:, content_type:)
      ensure
        body.close
        file.delete
      end

      def now_in_bdn_timezone
        Time.current.in_time_zone(BDN_TIMEZONE)
      end

      def prefixed_dated(prefix)
        "#{prefix}#{now_in_bdn_timezone.strftime('%Y%m%d%H%M%S')}.txt"
      end

      # Change of addresses send to Newman everyday.
      def address_changes_filename
        prefixed_dated 'CHGADD'
      end

      # Change of direct deposit send to Newman everyday.
      def direct_deposit_filename
        prefixed_dated 'DirDep'
      end

      # enrollment verification sent to BDN everyday.
      def verification_filename
        "vawave#{now_in_bdn_timezone.yday}"
      end

      public

      def check_args(bucket:, path:)
        case bucket
        when :external
          bucket = self.external_bucket
          raise ArgumentError, "invalid external path" unless path == 'inbound' || path == 'outbound'
        when :internal
          bucket = self.bucket
          raise ArgumentError, "invalid internal path" unless path == 'scanned' || path == 'processed'
        else
          raise ArgumentError, "bucket must be :external or :internal"
        end

        bucket
      end

      def list_uploaded(bucket: :internal, path: 'processed')
        bucket = check_args(bucket:, path:)
        prefix = "#{path}/"
        s3_client.list_objects_v2(bucket:, prefix: 'scanned/').contents.map do |obj|
          obj.key unless obj.key.ends_with?('/')
        end.compact
      end

      def clear_uploaded(bucket: :internal, path: 'processed')
        bucket = check_args(bucket:, path:)

        list_uploaded(bucket: :internal, path: 'processed').each do |key|
          s3_client.delete_object(bucket: bucket, key: key)
        end
      end

      def address_changes_upload
        date = Date.today.strftime("%Y-%m-%d")
        path = Rails.root / "tmp/vye/uploads/#{date}/#{address_changes_filename}"
        path.dirname.mkpath

        path2 = Vye::Engine.root / 'spec/fixtures/bdn_sample/WAVE.txt'
        FileUtils.cp(path2, path)

        # upload(path)
      end

      def direct_deposit_upload
        date = Date.today.strftime("%Y-%m-%d")
        path = Rails.root / "tmp/vye/uploads/#{date}/#{direct_deposit_filename}"
        path.dirname.mkpath

        path2 = Vye::Engine.root / 'spec/fixtures/bdn_sample/WAVE.txt'
        FileUtils.cp(path2, path)

        # upload(path)
      end

      def verification_upload
        date = Date.today.strftime("%Y-%m-%d")
        path = Rails.root / "tmp/vye/uploads/#{date}/#{verification_filename}"
        path.dirname.mkpath

        path2 = Vye::Engine.root / 'spec/fixtures/bdn_sample/WAVE.txt'
        FileUtils.cp(path2, path)

        # upload(path)
      end
    end
  end
end
