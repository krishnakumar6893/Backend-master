require 'test_helper'

describe Follow do
  let(:follower) { create(:user) }
  let(:follow)   { create(:follow, follower: follower) }

  subject { Follow }

  it { must belong_to(:user) }
  it { must belong_to(:follower) }

  it { must have_index_for(:user_id) }
  it { must have_index_for(:follower_id) }

  it { must validate_presence_of(:user_id) }
  it { must validate_presence_of(:follower_id) }
  it { must validate_uniqueness_of(:follower_id).scoped_to(:user_id).with_message('is already a friend!') }

  describe '#notif_target_user_id' do
    it 'should return its follower_id' do
      follow.notif_target_user_id.must_equal follower.id
    end
  end
end
