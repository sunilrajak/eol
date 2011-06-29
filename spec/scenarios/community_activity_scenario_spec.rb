require File.dirname(__FILE__) + '/../spec_helper'

describe 'Community Activity' do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching(:community_activity)
    @activity = EOL::TestInfo.load('community_activity')
  end

  it 'should 10 users and 10 communities' do
    @activity[:users].length.should == 10
    @activity[:communities].length.should == 10
  end

  it 'should have 10 owners, one for each community' do
    @activity[:communities].each_with_index do |community, i|
      community.has_member?(@activity[:owners][i]).should be_true
    end
  end

  it 'should have a busy user who joins all of the communities' do
    @activity[:communities].each do |community|
      community.has_member?(@activity[:busy_user]).should be_true
    end
  end

  it 'should have a fickle user who is NOT in any of the communities' do
    @activity[:communities].each do |community|
      community.has_member?(@activity[:fickle_user]).should_not be_true
    end
  end

  it 'should have a bunch of comments on communities' do
    user_comments = []
    curator_comments = []
    @activity[:communities].each do |community|
      # TODO - ActivityLog
    end
  end

end
