CarrierWave.configure do |config|
	config.s3_access_key_id = "AKIAICAIMQG2WGX7YOPQ"
	config.s3_secret_access_key = "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"
	config.s3_bucket = "mls-staging"
	config.s3_access_policy = :public_read
end
