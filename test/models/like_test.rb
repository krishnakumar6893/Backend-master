require 'test_helper'

describe Like do
  let(:like) { create(:like) }
  let(:user) { like.user }
  let(:default_signup_points) { 5 }

  subject { Like }

  it { must belong_to(:user) }
  it { must belong_to(:photo) }

  it { must have_index_for(:user_id) }
  it { must have_index_for(:photo_id) }

  it { must validate_uniqueness_of(:user_id).scoped_to(:photo_id).with_message('has already liked!') }

  describe '#notif_extid' do
    it 'should return its photo_id' do
      like.notif_extid.must_equal like.photo_id.to_s
    end
  end

  describe '#notif_context' do
    it 'should return its context' do
      like.notif_context.must_equal ['has liked']
    end
  end

  describe 'scope' do
    before do
      like
    end

    it 'should return likes by active users' do
      Like.all.must_include like
    end

    it 'should not return likes by inactive users' do
      like.user.update_attribute(:active, false)
      Like.all.wont_include like
    end
  end

  describe 'callbacks' do
    describe 'after_create' do
      it 'should add like points to user' do
        like.user.points.must_equal(Point.like_points + default_signup_points)
      end
    end

    describe 'after_destroy' do
      it 'should deduct like points from user' do
        like.destroy

        user.reload
        user.points.must_equal default_signup_points
      end

    end
  end

end
