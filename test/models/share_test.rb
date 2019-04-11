require 'test_helper'

describe Share do
  let(:photo)       { create(:photo) }
  let(:share)       { create(:share, photo: photo, user: photo.user) }
  let(:other_share) { create(:share) }

  let(:user) { share.user }
  let(:default_share_points) { 5 }


  subject { Share }

  it { must belong_to(:user) }
  it { must belong_to(:photo) }

  it { must have_index_for(:user_id) }
  it { must have_index_for(:photo_id) }

  it { must validate_presence_of(:user_id) }
  it { must validate_presence_of(:photo_id) }

  describe '#passive_points' do
    it 'should return 0' do
      share.passive_points.must_equal 0
    end

    it 'should return 5' do
      other_share.passive_points.must_equal 5
    end
  end

  describe '#owner_share?' do
    it 'should return true' do
      share.owner_share?.must_equal true
    end

    it 'should return false' do
      other_share.owner_share?.must_equal false
    end
  end

  describe 'callbacks' do
    describe 'after_create' do
      it 'should add share points to user' do
        share.user.points.must_equal(Point.share_points + default_share_points)
      end
    end

    describe 'after_destroy' do
      before do
        share
        user
      end

      it 'should deduct social login points from user' do
        share.destroy

        user.reload
        user.points.must_equal default_share_points
      end

    end
  end
end
