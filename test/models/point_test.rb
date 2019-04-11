require 'test_helper'

describe Point do
  subject { Point }

  it { must have_fields(:gain_point).of_type(Integer).with_default_value(0) }
  it { must have_fields(:from_user_id, :pointable_id).of_type(Object) }
  it { must have_fields(:created_at).of_type(Time) }

  it { must belong_to(:from_user) }
  it { must belong_to(:pointable) }

  it { must validate_presence_of(:pointable_id) }
  it { must validate_presence_of(:pointable_type) }

  it 'should not return incorrect like points' do
    Point.like_points.must_equal 1
  end

  it 'should not return incorrect social login points' do
    Point.social_login_points.must_equal 5
  end

  it 'should not return incorrect comment points' do
    Point.comment_points.must_equal 1
  end

  it 'should not return incorrect font tag points' do
    Point.font_tag_points.must_equal 2
  end

  it 'should not return incorrect share points' do
    Point.share_points.must_equal 5
  end

  it 'should not return incorrect ownerd share points' do
    Point.ownerd_share_points.must_equal 5
  end

  it 'should not return incorrect active points' do
    Point.active_points.must_equal 2
  end

end
