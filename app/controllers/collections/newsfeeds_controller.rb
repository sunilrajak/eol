class Collections::NewsfeedsController < CollectionsController

  before_filter :set_filter_to_newsfeed
  before_filter :find_collection
  before_filter :prepare_show
  before_filter :user_able_to_view_collection
  before_filter :find_parent

  layout 'v2/collections'

  def show
  end

private

  # This aids in the views and in the methods from the parent controller:
  def set_filter_to_newsfeed
    params[:filter] = 'newsfeed'
    @filter = 'newsfeed'
  end

end
