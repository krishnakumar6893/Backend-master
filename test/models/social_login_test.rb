require 'test_helper'

describe SocialLogin do
  let(:social_login) { create(:social_login) }
  let(:user) { social_login.user }
  let(:default_points)    { 5 }

  subject { SocialLogin }

  it { must have_fields(:platform).of_type(String).with_default_value('default') }

  describe '.by_extid' do
    before do
      social_login
    end

    it 'should return a social login found with the provide extuid' do
      SocialLogin.by_extid(social_login.extuid).must_equal social_login
    end
  end
end
