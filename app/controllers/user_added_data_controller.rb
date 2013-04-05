class UserAddedDataController < ApplicationController

  layout 'v2/basic'

  # POST /user_added_data
  def create
    delete_empty_metadata
    @user_added_data = UserAddedData.new(params[:user_added_data].reverse_merge(user: current_user))
    if @user_added_data.save
      flash[:notice] = I18n.t('user_added_data.create_successful')
    else
      # NOTE - we can't just use validation messages quite yet, since it's created in another controller. :\
      if @user_added_data.errors.any?
        flash[:error] = I18n.t('user_added_data.create_failed',
                               errors: @user_added_data.errors.full_messages.to_sentence)
      end
    end
    redirect_to taxon_data_path(@user_added_data.taxon_concept_id)
  end

  # GET /user_added_data/:id/edit
  def edit
    @user_added_data = UserAddedData.find(params[:id])
    unless current_user.can_update?(@user_added_data)
      raise EOL::Exceptions::SecurityViolation,
        "User with ID=#{current_user.id} does not have edit access to UserAddedData with ID=#{@user_added_data.id}"
    end
  end

  # PUT /user_added_data/:id
  def update
    delete_empty_metadata
    @user_added_data = UserAddedData.find(params[:id])
    unless current_user.can_update?(@user_added_data)
      raise EOL::Exceptions::SecurityViolation,
        "User with ID=#{current_user.id} does not have edit access to UserAddedData with ID=#{@user_added_data.id}"
    end
    if @user_added_data.update_attributes(params[:user_added_data])
      flash[:notice] = I18n.t('user_added_data.update_successful')
    else
      flash[:error] = I18n.t('user_added_data.update_failed',
                             errors: @user_added_data.errors.full_messages.to_sentence)
      render :edit
      return
    end
    redirect_to taxon_data_path(@user_added_data.subject_id)
  end

  # DELETE /user_added_data/:id
  def destroy
    user_added_data = UserAddedData.find(params[:id])
    raise EOL::Exceptions::SecurityViolation,
      "User with ID=#{current_user.id} does not have edit access to UserAddedData with ID=#{@user_added_data.id}" unless current_user.can_delete?(user_added_data)
    user_added_data.update_attributes({ :deleted_at => Time.now })
    flash[:notice] = I18n.t('user_added_data.delete_successful')
    redirect_to taxon_data_path(user_added_data.taxon_concept_id)
  end

  private

  def delete_empty_metadata
    params['user_added_data']['user_added_data_metadata_attributes'].delete_if{ |k,v| v['id'].blank? && v['predicate'].blank? && v['object'].blank? }
  end
end
