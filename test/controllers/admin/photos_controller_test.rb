require 'test_helper'

describe Admin::PhotosController do
  let(:photo) { create(:photo, :with_caption) }

  before do
    create(:user, username: 'fontli')
    @controller = Admin::PhotosController.new
    @controller.stubs(:admin_required).returns(true)
  end

  describe '#update' do
    let(:caption)    { Faker::Lorem.word }
    let(:collection) { create(:collection) }

    it 'should update caption' do
      xhr :put, :update, id: photo.id, photo: { caption: caption }
      photo.reload.caption.must_equal caption
    end

    it 'should update collections' do
      photo.collections.must_be_empty
      xhr :put, :update, id: photo.id, photo: { collection_names: collection.name }
      photo.reload.collections.wont_be_empty
    end
  end
end
