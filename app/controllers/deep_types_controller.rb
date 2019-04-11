class DeepTypesController < ApplicationController
  skip_before_filter :login_required
  skip_before_filter :verify_authenticity_token

  # Accepts body containing json...
  # => {  "style_image_path": "path",
  # =>    "content_image_path":"path",
  # =>    "result_image_path":"path",
  # =>    "result_image_name":"name"
  # =>    "status":"status"
  # => }

  def status
    deep_type = DeepType.where(result_image_name: params[:result_image_name]).last

    if deep_type
      deep_type.update_attributes(status: params[:status], result_image_path: params[:result_image_path])
      Notification.create(to_user_id: deep_type.user_id, notifiable: deep_type) if deep_type.user
    end

    render nothing: true, :status => 200
  end

  def history
    # Get all the result image urls of specific user
    user = User.find(params[:user_id])
    public_urls = DeepType.get_history(params[:user_id])
    render json: { body: public_urls, status: 'Success', points: user.points }
  end

  def styles
    render :json => { body: DeepType.get_style_values, status: "Success" }
  end

  def destroy
    deep_type = DeepType.where(id: params[:id]).last
    response = if deep_type && deep_type.destroy
                 { body: "", status: "Success" }
               else
                 { body: "", status: "Failure", error: 'Invalid ID' }
               end
    render :json => response
  end

  # Accepts body containing json...
  # => {  "user_id": "id",
  # =>    "priority":"low",
  # =>    "style_image_id":"style_image_name",
  # =>    "content_image":"multipart image"
  # => }

  def submission
    response = DeepType.create_submission(params)
    render json: response
  end
end
