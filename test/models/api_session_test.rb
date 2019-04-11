require 'test_helper'

describe ApiSession do
  let(:api_session)     { create(:api_session) }
  let(:active_session)  { create(:api_session, auth_token: SecureRandom.hex, expires_at: Time.zone.now + 7.days) }
  let(:expired_session) { create(:api_session, auth_token: SecureRandom.hex, expires_at: Time.zone.now - 7.days) }

  subject { ApiSession }

  it { must have_fields(:device_id, :auth_token).of_type(String) }
  it { must have_fields(:expires_at).of_type(Time) }

  it { must belong_to(:user) }

  it { must have_index_for(:user_id) }
  it { must have_index_for(:auth_token, :device_id) }

  it { must validate_presence_of(:user_id) }
  it { must validate_presence_of(:device_id) }

  describe '.[]' do
    it 'should find session with the provided token and device_id' do
      ApiSession[api_session.auth_token, api_session.device_id].must_equal api_session
    end
  end

  describe '#activate' do
    before do
      api_session.activate
    end

    it 'should set the auth_token' do
      api_session.auth_token.wont_be_nil
    end

    it 'should set the expires_at' do
      api_session.expires_at.wont_be_nil
    end

    it 'should set a 32-character auth_token' do
      api_session.auth_token.length.must_equal 32
    end
  end

  describe '#deactivate' do
    let(:android_user_session) { create(:api_session, user: create(:user, android_registration_id: SecureRandom.hex(6))) }
    let(:iphone_user_session)  { create(:api_session, user: create(:user, iphone_token: SecureRandom.hex(6))) }

    it 'should set the auth_token to nil' do
      active_session.deactivate
      active_session.reload.auth_token.must_be_nil
    end

    it 'should not remove auth_token if session is not deactivated' do
      active_session.device_id = nil
      active_session.save(validate: false)
      active_session.deactivate
      active_session.reload.auth_token.wont_be_nil
    end

    it 'should set the iphone_token to nil' do
      iphone_user_session.deactivate
      iphone_user_session.user.reload.iphone_token.must_be_nil
    end

    it 'should set the android_registration_id to nil' do
      android_user_session.deactivate
      android_user_session.user.reload.android_registration_id.must_be_nil
    end
  end

  describe '#active?' do
    it 'should return true' do
      active_session.active?.must_equal true
    end

    it 'should return false' do
      expired_session.active?.must_equal false
    end
  end
end
