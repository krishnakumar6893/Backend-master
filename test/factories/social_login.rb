FactoryGirl.define do
  factory SocialLogin do
    platform  %w(twitter facebook).sample
    extuid    { SecureRandom.hex(6) }
    user
  end
end
